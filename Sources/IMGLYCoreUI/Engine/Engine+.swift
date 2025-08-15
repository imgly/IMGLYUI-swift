@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI
import UniformTypeIdentifiers

@_spi(Internal) public enum HistoryResetBehavior {
  case always
  case ifNeeded
  case never
}

private struct Random: RandomNumberGenerator {
  init(seed: Int) {
    srand48(seed)
  }

  func next() -> UInt64 {
    // swiftlint:disable:next legacy_random
    UInt64(drand48() * Double(UInt64.max))
  }
}

@_spi(Internal) public extension Engine {
  private var engine: Engine { self }

  private static var rng: RandomNumberGenerator = ProcessInfo
    .isUITesting ? Random(seed: 0) : SystemRandomNumberGenerator()

  // MARK: - Scene

  static let outlineBlockName = "always-on-top-page-outline"

  func showOutline(_ isVisible: Bool) throws {
    let outline = try getOutline()
    try engine.block.setVisible(outline, visible: isVisible)
    // Workaround: Trigger opacity to force refresh on "fast" devices.
    try engine.block.setOpacity(outline, value: isVisible ? 1 : 0)
  }

  func selectionColors(
    forPage index: Int,
    includeUnnamed: Bool = false,
    includeDisabled: Bool = false,
    setDisabled: Bool = false,
    ignoreScope: Bool = false
  ) throws -> SelectionColors {
    try selectionColors(
      getPage(index),
      includeUnnamed: includeUnnamed,
      includeDisabled: includeDisabled,
      setDisabled: setDisabled,
      ignoreScope: ignoreScope
    )
  }

  private func getSelectionColors(_ id: DesignBlockID, includeUnnamed: Bool, includeDisabled: Bool, setDisabled: Bool,
                                  ignoreScope: Bool, selectionColors: inout SelectionColors) throws {
    let fillChangeEnabled = try engine.block.isScopeEnabled(id, scope: .key(.fillChange))
    let strokeChangeEnabled = try engine.block.isScopeEnabled(id, scope: .key(.strokeChange))

    guard (fillChangeEnabled && strokeChangeEnabled) || ignoreScope else {
      return
    }
    let name = try engine.block.getName(id)
    guard !name.isEmpty || includeUnnamed else {
      return
    }

    func addColor(property: Property, includeDisabled: Bool = false) throws -> CGColor? {
      guard let enabled = property.enabled, try engine.block.get(id, property: enabled) || includeDisabled else {
        return nil
      }
      if property == .key(.fillSolidColor),
         let fillType: ColorFillType = try? engine.block.get(id, .fill, property: .key(.type)),
         fillType == .gradient {
        let colorStops: [GradientColorStop] = try engine.block.get(id, .fill, property: .key(.fillGradientColors))
        if let color = colorStops.first?.color.cgColor {
          selectionColors.add(id, property: property, value: color, name: name)
          return color
        }
        return nil
      } else {
        let color: CGColor = try engine.block.get(id, property: property)
        selectionColors.add(id, property: property, value: color, name: name)
        return color
      }
    }

    let hasFill = try engine.block.supportsFill(id)
    let hasStroke = try engine.block.supportsStroke(id)

    if hasFill, hasStroke {
      // Assign enabled color to disabled color to ease template creation.
      let fillColor = try addColor(property: .key(.fillSolidColor))
      let strokeColor = try addColor(property: .key(.strokeColor))

      func setAndAddColor(property: Property, color: CGColor) throws {
        if setDisabled, try engine.block.get(id, property: property) != color {
          try engine.block.overrideAndRestore([id], scopes: [.key(.fillChange), .key(.strokeChange)]) {
            _ = try engine.block.set($0, property: property, value: color)
          }
        }
        _ = try addColor(property: property, includeDisabled: includeDisabled)
      }

      if fillColor == nil, let strokeColor {
        try setAndAddColor(property: .key(.fillSolidColor), color: strokeColor)
      } else if strokeColor == nil, let fillColor {
        try setAndAddColor(property: .key(.strokeColor), color: fillColor)
      } else {
        _ = try addColor(property: .key(.fillSolidColor), includeDisabled: includeDisabled)
        _ = try addColor(property: .key(.strokeColor), includeDisabled: includeDisabled)
      }
    } else if hasFill {
      _ = try addColor(property: .key(.fillSolidColor), includeDisabled: includeDisabled)
    } else if hasStroke {
      _ = try addColor(property: .key(.strokeColor), includeDisabled: includeDisabled)
    }
  }

  /// Traverse design block hierarchy and collect used colors.
  /// - Attention: Use `setDisabled` with care!
  /// - Parameters:
  ///   - id: Parent block `id` to start traversal.
  ///   - includeUnnamed: Include colors of unnamed blocks.
  ///   - includeDisabled: Include currently invisible colors of disabled properties.
  ///   - setDisabled: Assign colors of enabled properties to colors of disabled properties of the same block to ease
  /// scene template creation.
  /// - Returns: The collected selection colors.
  func selectionColors(_ id: DesignBlockID, includeUnnamed: Bool, includeDisabled: Bool,
                       setDisabled: Bool, ignoreScope: Bool) throws -> SelectionColors {
    if setDisabled {
      print(
        // swiftlint:disable:next line_length
        "Assigning colors of enabled properties to colors of disabled properties of the same block while collecting selection colors."
      )
    }
    func traverse(_ id: DesignBlockID, selectionColors: inout SelectionColors) throws {
      try getSelectionColors(
        id,
        includeUnnamed: includeUnnamed,
        includeDisabled: includeDisabled,
        setDisabled: setDisabled,
        ignoreScope: ignoreScope,
        selectionColors: &selectionColors
      )
      let children = try engine.block.getChildren(id)
      for child in children {
        try traverse(child, selectionColors: &selectionColors)
      }
    }

    var selectionColors = SelectionColors()
    try traverse(id, selectionColors: &selectionColors)

    return selectionColors
  }

  // MARK: - Zoom

  func showAllPages(layout: LayoutAxis, spacing: Float = 16) throws {
    try showPage(index: nil, layout: layout, spacing: spacing)
  }

  func showPage(_ index: Int, historyResetBehavior: HistoryResetBehavior = .never, deselectAll: Bool = true) throws {
    try showPage(index: index, layout: .depth, historyResetBehavior: historyResetBehavior, deselectAll: deselectAll)
  }

  private func showPage(
    index: Int?,
    layout axis: LayoutAxis,
    spacing: Float? = nil,
    historyResetBehavior: HistoryResetBehavior = .never,
    deselectAll: Bool = true
  ) throws {
    if deselectAll {
      try engine.block.deselectAll()
    }

    switch historyResetBehavior {
    case .always:
      try engine.editor.resetHistory()
    case .ifNeeded:
      if !(try engine.editor.canUndo() || engine.editor.canRedo()) {
        try engine.editor.resetHistory()
      }
    case .never:
      break
    }

    let allPages = index == nil

    if let stack = try? getStack() {
      try engine.block.set(stack, property: .key(.stackAxis), value: axis)
      if let spacing {
        try engine.block.set(stack, property: .key(.stackSpacing), value: spacing)
      }
    }

    let pages = try getSortedPages()
    for (i, block) in pages.enumerated() {
      try engine.block.overrideAndRestore(block, scope: .key(.layerVisibility)) {
        try engine.block.setVisible($0, visible: allPages || i == index)
      }
    }
  }

  func zoomToBackdrop(_ insets: EdgeInsets?) async throws {
    try await zoomToBlock(getBackdropImage(), with: insets)
  }

  func zoomToScene(_ insets: EdgeInsets?) async throws {
    try await zoomToBlock(getScene(), with: insets)
  }

  func zoomToPage(_ index: Int, _ insets: EdgeInsets?, zoomModel: ZoomModel) async throws -> Float? {
    try await updateZoom(with: insets, zoomToPage: true, pageIndex: index, zoomModel: zoomModel)
  }

  func zoomToBlock(_ block: DesignBlockID, with insets: EdgeInsets?) async throws {
    try await engine.scene.zoom(
      to: block,
      paddingLeft: Float(insets?.leading ?? 0),
      paddingTop: Float(insets?.top ?? 0),
      paddingRight: Float(insets?.trailing ?? 0),
      paddingBottom: Float(insets?.bottom ?? 0)
    )
  }

  func zoomToSelectedText(_ insets: EdgeInsets?, canvasHeight: CGFloat) throws {
    let paddingTop = insets?.top ?? 0
    let paddingBottom = insets?.bottom ?? 0

    let overlapTop: CGFloat = 50
    let overlapBottom: CGFloat = 50

    let selectedTexts = engine.block.findAllSelected()
    if selectedTexts.count == 1 {
      let cursorPosY = CGFloat(engine.editor.getTextCursorPositionInScreenSpaceY())
      // The first cursorPosY is 0 if no cursor has been layouted yet. Then we ignore zoom commands.
      let cursorPosIsValid = cursorPosY != 0
      if !cursorPosIsValid {
        return
      }
      let visiblePageAreaY = (canvasHeight - overlapBottom - paddingBottom)

      let visiblePageAreaYCanvas = try pointToCanvasUnit(visiblePageAreaY)
      let cursorPosYCanvas = try pointToCanvasUnit(cursorPosY)
      let cameraPosY = try engine.block.getPositionY(getCamera())

      let newCameraPosY = cursorPosYCanvas + cameraPosY - visiblePageAreaYCanvas

      if cursorPosY > visiblePageAreaY ||
        cursorPosY < (overlapTop + paddingTop) {
        try engine.block.overrideAndRestore(getCamera(), scope: .key(.layerMove)) {
          try engine.block.setPositionY($0, value: newCameraPosY)
        }
      }
    }
  }

  func updateZoom(
    with insets: EdgeInsets?,
    and canvasHeight: CGFloat? = nil,
    zoomToPage: Bool = false,
    clampOnly: Bool = false,
    pageIndex: Int,
    zoomModel: ZoomModel
  ) async throws -> Float? {
    var updatedDefaultZoomLevel: Float?

    var updatedInsets = insets ?? zoomModel.defaultInsets
    updatedInsets.leading += zoomModel.padding
    updatedInsets.trailing += zoomModel.padding
    updatedInsets.top += zoomModel.padding
    updatedInsets.bottom += zoomModel.padding

    let paddingLeft = Float(updatedInsets.leading)
    let paddingRight = Float(updatedInsets.trailing)
    let paddingTop = Float(updatedInsets.top)
    let paddingBottom = Float(updatedInsets.bottom)
    let margin = Float(zoomModel.defaultPadding + zoomModel.padding)
    let page = try engine.getPage(pageIndex)

    let zoomLevel = try engine.scene.getZoom()
    let selection = engine.block.findAllSelected().first
    let editMode = engine.editor.getEditMode()
    var blocks = [page]

    if let selection, editMode == .text {
      blocks.append(selection)
    }

    // If the zoom level is at 100%, we need to zoom clamp the page.
    let isDefaultZoomLevel = zoomModel.defaultZoomLevel == zoomLevel

    // Otherwise, we should zoom to the page if either:
    // 1. `zoomToPage` is true AND the edit mode is not text
    // 2. OR the selection is `nil`
    let shouldZoomToPage = ((zoomToPage && editMode != .text) || selection == nil)

    try engine.scene.unstable_enableCameraPositionClamping(blocks,
                                                           paddingLeft: paddingLeft - margin,
                                                           paddingTop: paddingTop - margin,
                                                           paddingRight: paddingRight - margin,
                                                           paddingBottom: paddingBottom - margin,
                                                           scaledPaddingLeft: margin,
                                                           scaledPaddingTop: margin,
                                                           scaledPaddingRight: margin,
                                                           scaledPaddingBottom: margin)

    // If `clampOnly` is enabled, we only need position clamping.
    if (!clampOnly && shouldZoomToPage) || isDefaultZoomLevel {
      try engine.scene.unstable_enableCameraZoomClamping(blocks, minZoomLimit: 1,
                                                         maxZoomLimit: 5,
                                                         paddingLeft: paddingLeft,
                                                         paddingTop: paddingTop,
                                                         paddingRight: paddingRight,
                                                         paddingBottom: paddingBottom)
      try await zoomToBlock(page, with: updatedInsets)
      let zoom = try engine.scene.getZoom()
      updatedDefaultZoomLevel = zoom
    }

    if let selection, !zoomToPage, editMode != .text {
      let boundingBox = try engine.block.getScreenSpaceBoundingBox(containing: [selection])

      let camera = try engine.getCamera()
      let oldCameraPosX = try engine.block.getPositionX(camera)
      let oldCameraPosY = try engine.block.getPositionY(camera)
      var newCameraPosX = oldCameraPosX
      var newCameraPosY = oldCameraPosY
      let resolution: Float = try engine.block.get(camera, property: .key(.cameraResolutionWidth))
      let pixelRatio: Float = try engine.block.get(camera, property: .key(.cameraPixelRatio))
      let canvasWidthPt = resolution / pixelRatio
      let boundingBoxCenterX = Float(boundingBox.midX)

      if boundingBoxCenterX > canvasWidthPt {
        let first = (CGFloat(canvasWidthPt) / 2 - boundingBox.size.width / 2)
        let second = (boundingBox.maxX - CGFloat(canvasWidthPt))
        let new = try engine.pointToCanvasUnit(first + second)
        newCameraPosX = oldCameraPosX + new
      } else if boundingBoxCenterX < 0 {
        let first = (CGFloat(canvasWidthPt) / 2 - boundingBox.size.width / 2)
        let new = try engine.pointToCanvasUnit(first - boundingBox.minX)
        newCameraPosX = oldCameraPosX - new
      }

      // bottom sheet is covering more than 50% of selected block
      if let canvasHeight, let bottomSheetHeight = insets?.bottom {
        let bottomSheetTop = canvasHeight - bottomSheetHeight
        if bottomSheetTop < boundingBox.midY {
          let converted = try engine.pointToCanvasUnit(48 + boundingBox.maxY - bottomSheetTop)
          newCameraPosY = oldCameraPosY + converted
        } else if boundingBox.midY < 64 {
          let converted = try engine.pointToCanvasUnit(48 + bottomSheetTop - boundingBox.maxY)
          newCameraPosY = oldCameraPosY - converted
        }
      }

      if newCameraPosX != oldCameraPosX || newCameraPosY != oldCameraPosY {
        try engine.block.overrideAndRestore(camera, scope: .key(.layerMove)) {
          try engine.block.setPositionX($0, value: newCameraPosX)
          try engine.block.setPositionY($0, value: newCameraPosY)
        }
      }
    }
    return updatedDefaultZoomLevel
  }

  // MARK: - Actions

  func bringToFrontSelectedElement() throws {
    try engine.block.findAllSelected().forEach {
      try engine.block.bringToFront($0)
    }
    try engine.editor.addUndoStep()
  }

  func bringForwardSelectedElement() throws {
    try bringForward(engine.block.findAllSelected())
  }

  func bringForward(_ ids: [DesignBlockID]) throws {
    try ids.forEach {
      try engine.block.bringForward($0)
    }
    try engine.editor.addUndoStep()
  }

  func sendBackwardSelectedElement() throws {
    try sendBackward(engine.block.findAllSelected())
  }

  func sendBackward(_ ids: [DesignBlockID]) throws {
    try ids.forEach {
      try engine.block.sendBackward($0)
    }
    try engine.editor.addUndoStep()
  }

  func sendToBackSelectedElement() throws {
    try engine.block.findAllSelected().forEach {
      try engine.block.sendToBack($0)
    }
    try engine.editor.addUndoStep()
  }

  func duplicateSelectedElement() throws {
    try duplicate(engine.block.findAllSelected())
  }

  func duplicate(_ ids: [DesignBlockID]) throws {
    try ids.forEach {
      let duplicate = try engine.block.duplicate($0)

      let isPage = try engine.block.getType($0) == DesignBlockType.page.rawValue
      if !isPage, try !engine.block.isTransformLocked($0) {
        // Remember values
        let positionModeX = try engine.block.getPositionXMode($0)
        let positionModeY = try engine.block.getPositionYMode($0)

        try engine.block.overrideAndRestore($0, scope: .key(.layerMove)) {
          try engine.block.setPositionXMode($0, mode: .absolute)
          let x = try engine.block.getPositionX($0)
          try engine.block.setPositionYMode($0, mode: .absolute)
          let y = try engine.block.getPositionY($0)

          try engine.block.setPositionXMode(duplicate, mode: .absolute)
          try engine.block.setPositionX(duplicate, value: x + 5)
          try engine.block.setPositionYMode(duplicate, mode: .absolute)
          try engine.block.setPositionY(duplicate, value: y - 5)

          // Restore values
          try engine.block.setPositionXMode($0, mode: positionModeX)
          try engine.block.setPositionYMode($0, mode: positionModeY)
        }
      }

      if try engine.block.getKind(duplicate) == .key(.sticker) {
        try engine.block.setScopeEnabled(duplicate, scope: .key(.layerCrop), enabled: false)
      }

      if !isPage {
        try engine.block.setSelected(duplicate, selected: true)
        try engine.block.setSelected($0, selected: false)
      }
    }
    try engine.editor.addUndoStep()
  }

  func deleteSelectedElement(delay nanoseconds: UInt64 = .zero) throws {
    try delete(engine.block.findAllSelected(), delay: nanoseconds)
  }

  func delete(_ ids: [DesignBlockID], delay nanoseconds: UInt64 = .zero) throws {
    func delete() throws {
      try ids.forEach {
        try engine.block.destroy($0)
      }
      try engine.editor.addUndoStep()
    }

    if nanoseconds != .zero {
      // Delay real deletion, e.g., to wait for sheet disappear animations
      // to complete but fake deletion in the meantime.
      try ids.forEach {
        if try engine.block.supportsOpacity($0) {
          try engine.block.overrideAndRestore($0, scope: .key(.layerOpacity)) {
            try engine.block.setOpacity($0, value: 0)
          }
          try engine.block.setSelected($0, selected: false)
        }
      }
      Task {
        try await Task.sleep(nanoseconds: nanoseconds)
        try delete()
      }
    } else {
      try delete()
    }
  }

  func resetCropSelectedElement() throws {
    try engine.block.findAllSelected().forEach {
      try engine.block.resetCrop($0)
    }
    try engine.editor.addUndoStep()
  }

  func flipCropSelectedElement() throws {
    try engine.block.findAllSelected().forEach {
      try engine.block.flipCropHorizontal($0)
    }
    try engine.editor.addUndoStep()
  }

  // MARK: - Utilities

  func pointToCanvasUnit(_ point: CGFloat) throws -> Float {
    let sceneUnit = try engine.block.getEnum(getScene(), property: "scene/designUnit")
    let sceneDpi: Float = try engine.block.get(getScene(), property: .key(.sceneDPI))
    var densityFactor: Float = 1
    if sceneUnit == "Millimeter" {
      densityFactor = sceneDpi / 25.4
    }
    if sceneUnit == "Inch" {
      densityFactor = sceneDpi
    }
    let zoomLevel = try engine.scene.getZoom()
    let pixelRatio: Float = try engine.block.get(getCamera(), property: .key(.cameraPixelRatio))
    return (Float(point) * pixelRatio) / (densityFactor * zoomLevel)
  }

  // All non-text blocks in this demo should be added with the same square size
  private func setSize(_ block: DesignBlockID) throws {
    try engine.block.setHeightMode(block, mode: .absolute)
    try engine.block.setHeight(block, value: 40)
    try engine.block.setWidthMode(block, mode: .absolute)
    try engine.block.setWidth(block, value: 40)
  }

  // Appends a block into the scene and positions it somewhat randomly.
  private func addBlock(_ block: DesignBlockID, toPage index: Int) throws {
    try engine.block.deselectAll()
    try engine.block.appendChild(to: getPage(index), child: block)

    try engine.block.setPositionXMode(block, mode: .absolute)
    try engine.block.setPositionX(block, value: 15 + Float.random(in: 0 ... 1, using: &Self.rng) * 20)
    try engine.block.setPositionYMode(block, mode: .absolute)
    try engine.block.setPositionY(block, value: 5 + Float.random(in: 0 ... 1, using: &Self.rng) * 20)

    try engine.block.setSelected(block, selected: true)
    try engine.editor.addUndoStep()
  }

  func addPage(_ index: Int) throws {
    guard let currentPage = try engine.scene.getCurrentPage(),
          let parent = try engine.block.getParent(currentPage) else {
      throw Error(errorDescription: "Invalid current page.")
    }
    let newPage = try engine.block.create(.page)
    try engine.block.setWidthMode(newPage, mode: engine.block.getWidthMode(currentPage))
    try engine.block.setHeightMode(newPage, mode: engine.block.getHeightMode(currentPage))
    try engine.block.setWidth(newPage, value: engine.block.getWidth(currentPage))
    try engine.block.setHeight(newPage, value: engine.block.getHeight(currentPage))
    try engine.block.insertChild(into: parent, child: newPage, at: index)
    try engine.editor.addUndoStep()
  }

  // Note: Backdrop Images are not officially supported yet.
  // The backdrop image is the only image that is a direct child of the scene block.
  private func getBackdropImage() throws -> DesignBlockID {
    let childIDs = try engine.block.getChildren(getScene())
    let imageID = try childIDs.first {
      guard try engine.block.getType($0) == DesignBlockType.graphic.rawValue, try engine.block.supportsFill($0) else {
        return false
      }
      return try engine.block.getType(try engine.block.getFill($0)) == FillType.image.rawValue
    }
    guard let imageID else {
      throw Error(errorDescription: "No backdrop image found.")
    }
    return imageID
  }

  private func getAllSelectedElements(of elementType: DesignBlockType? = nil) throws -> [DesignBlockID] {
    try getAllSelectedElements(of: elementType?.rawValue)
  }

  private func getAllSelectedElements(of elementType: String? = nil) throws -> [DesignBlockID] {
    let allSelected = engine.block.findAllSelected()

    guard let elementType else {
      return allSelected
    }

    return try allSelected.filter {
      try engine.block.getType($0).starts(with: elementType)
    }
  }

  func getCamera() throws -> DesignBlockID {
    guard let camera = try engine.block.find(byType: .camera).first else {
      throw Error(errorDescription: "No camera found.")
    }
    return camera
  }

  func getStack() throws -> DesignBlockID {
    guard let stack = try engine.block.find(byType: .stack).first else {
      throw Error(errorDescription: "No stack found.")
    }
    return stack
  }

  func getPage(_ index: Int) throws -> DesignBlockID {
    let pages = try getSortedPages()
    guard index < pages.endIndex else {
      throw Error(errorDescription: "Invalid page index.")
    }
    return pages[index]
  }

  func getSortedPages() throws -> [DesignBlockID] {
    guard (try? engine.scene.get()) != nil else { return [] }
    return try engine.scene.getPages()
  }

  func getPageIndex(_ id: DesignBlockID) throws -> Int {
    guard let pageIndex = try getSortedPages().firstIndex(of: id) else {
      throw Error(errorDescription: "Page not found.")
    }
    return pageIndex
  }

  func getCurrentPageIndex() throws -> Int {
    guard (try? engine.scene.get()) != nil else {
      throw Error(errorDescription: "No scene found.")
    }
    guard let currentPage = try engine.scene.getCurrentPage() else {
      throw Error(errorDescription: "No current page available.")
    }
    guard let currentPageIndex = try engine.scene.getPages().firstIndex(of: currentPage) else {
      throw Error(errorDescription: "No current page found.")
    }
    return currentPageIndex
  }

  func getScene() throws -> DesignBlockID {
    guard let scene = try engine.block.find(byType: .scene).first else {
      throw Error(errorDescription: "No scene found.")
    }
    return scene
  }

  private func getOutline() throws -> DesignBlockID {
    guard let outline = engine.block.find(byName: Self.outlineBlockName).first else {
      throw Error(errorDescription: "No outline found.")
    }
    return outline
  }
}
