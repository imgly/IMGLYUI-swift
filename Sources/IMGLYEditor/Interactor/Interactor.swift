import Combine
import CoreMedia
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

@MainActor
@_spi(Internal) public final class Interactor: ObservableObject, KeyboardObserver {
  // MARK: - Properties

  @_spi(Internal) public let config: EngineConfiguration

  @ViewBuilder var spinner: some View {
    ProgressView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder var canvas: some View {
    if let engine {
      ZStack {
        IMGLYEngine.Canvas(engine: engine)
          .opacity(isCreating ? 0 : 1)
        if isCreating {
          spinner
        }
      }
    } else {
      spinner
    }
  }

  let fontLibrary = FontLibrary()

  @Published @_spi(Internal) public private(set) var isCreating = true
  @Published private(set) var viewMode = EditorViewMode.edit
  var isPreviewMode: Bool { viewMode == .preview }
  var isPagesMode: Bool { viewMode == .pages }
  @Published private(set) var isExporting = false
  @Published @_spi(Internal) public private(set) var isAddingAsset = false

  @Published var error = AlertState()
  @Published var sheet = SheetState() { didSet { sheetChanged(oldValue) } }
  @Published var shareItem: ShareItem?
  var export = ExportSheetState()
  var dismiss: DismissAction?

  typealias BlockID = IMGLYEngine.DesignBlockID
  typealias BlockType = IMGLYEngine.DesignBlockType
  typealias EditMode = IMGLYEngine.EditMode
  typealias RGBA = IMGLYEngine.RGBA
  typealias GradientColorStop = IMGLYEngine.GradientColorStop
  typealias Color = IMGLYEngine.Color
  typealias DefaultAssetSource = Engine.DefaultAssetSource
  typealias BlurType = IMGLYEngine.BlurType
  typealias EffectType = IMGLYEngine.EffectType
  typealias Font = IMGLYEngine.Font
  typealias TextCase = IMGLYEngine.TextCase
  typealias DesignUnit = IMGLYEngine.DesignUnit
  typealias FillType = IMGLYEngine.FillType

  struct Selection: Equatable {
    let blocks: [BlockID]
    let boundingBox: CGRect
  }

  @Published var verticalSizeClass: UserInterfaceSizeClass?
  @Published @_spi(Internal) public private(set) var page = 0 { didSet { pageChanged(oldValue) } }
  @Published var pageOverview = PageOverviewState() { didSet { pageOverviewChanged(oldValue) } }
  @Published @_spi(Internal) public var selectionColors = SelectionColors()
  @Published private(set) var selection: Selection? { didSet { selectionChanged(oldValue) } }
  @Published private(set) var editMode: EditMode = .transform { didSet { editModeChanged(oldValue) } }
  @Published private(set) var textCursorPosition: CGPoint?
  @Published private(set) var canUndo = false
  @Published private(set) var canRedo = false
  @Published private var isKeyboardPresented = false
  @Published private(set) var isDefaultZoomLevel = false
  @Published var isCameraSheetShown = false
  @Published var isSystemCameraShown = false
  @Published var isImagePickerShown = false

  @Published var isLoopingPlaybackEnabled = true
  @Published var isSelectionVisible = true

  var uploadAssetSourceIDs: [MediaType: String] = EditorEvents.AddFrom.defaultAssetSourceIDs
  var imageUploadAssetSourceID: String { uploadAssetSourceIDs[.image] ?? Engine.DemoAssetSource.imageUpload.rawValue }
  var videoUploadAssetSourceID: String { uploadAssetSourceIDs[.movie] ?? Engine.DemoAssetSource.videoUpload.rawValue }

  var isAddingCameraRecording = false

  @_spi(Internal) public var zoomModel = ZoomModel() { didSet { zoomLevelChanged(zoomModel.defaultZoomLevel) } }
  var defaultPinchAction: String = ""

  var pageCount: Int {
    (try? engine?.getSortedPages().count) ?? 0
  }

  func generatePageThumbnail(_ id: BlockID, height: CGFloat) async throws -> UIImage {
    guard let engine else {
      throw Error(errorDescription: "Engine unavailable.")
    }
    return try await engine.block.generatePageThumbnail(id, height: height, scale: UIScreen.main.scale)
  }

  var isCanvasHitTestingEnabled: Bool {
    behavior.previewMode == .scrollable || !isPreviewMode
  }

  var sceneMode: SceneMode? {
    // Make sure scene is loaded before calling `scene.getMode()` as it'll force unwrap the scene.
    guard let engine, (try? engine.scene.get()) != nil else {
      return nil
    }
    return try? engine.scene.getMode()
  }

  var isCanvasActionEnabled: Bool {
    !isCreating && !sheet
      .isPresented && editMode == .transform && isSelectionVisible && sheetContentForSelection != .page &&
      timelineProperties.selectedClip?.clipType != .voiceOver
  }

  var sheetContentForSelection: SheetContent? {
    isCreating ? nil : sheetContent(for: selection)
  }

  var sheetContentForBottomBar: SheetContent? {
    guard isBottomBarEnabled else {
      return nil
    }
    return isPagesMode ? .pageOverview : sheetContentForSelection
  }

  var isBottomBarEnabled: Bool {
    guard let engine else {
      return false
    }
    do {
      return try behavior.isBottomBarEnabled(.init(engine, self))
    } catch {
      handleErrorWithTask(error)
      return false
    }
  }

  func sheetContent(_ id: BlockID?) -> SheetContent? {
    guard let id, let engine, let type = try? engine.block.getType(id) else {
      return nil
    }
    let fill = try? engine.block.getFill(id)
    let kind: BlockKind? = try? engine.block.getKind(id)
    var fillType: String?
    if let fill {
      fillType = try? engine.block.getType(fill)
    }
    return sheetContent(for: type, with: fillType, and: kind)
  }

  func shapeType(_ id: BlockID?) -> ShapeType? {
    guard let id, let engine, let shape = try? engine.block.getShape(id),
          let type = try? engine.block.getType(shape) else {
      return nil
    }
    return ShapeType(rawValue: type)
  }

  var rotationForSelection: CGFloat? {
    guard let first = selection?.blocks.first,
          let rotation = try? engine?.block.getRotation(first) else {
      return nil
    }
    return CGFloat(rotation)
  }

  func isGestureActive(_ started: Bool) {
    guard let engine else {
      return
    }
    do {
      try behavior.isGestureActive(.init(engine, self), started)
    } catch {
      handleError(error)
    }
  }

  var rootBottomBarItems: [RootBottomBarItem] {
    guard let engine else {
      return []
    }
    do {
      return try behavior.rootBottomBarItems(.init(engine, self))
    } catch {
      handleErrorWithTask(error)
      return []
    }
  }

  /// All timeline-specific properties are bundled here.
  var timelineProperties = TimelineProperties()

  @_spi(Internal) public var backgroundTracksItemCount: Int {
    timelineProperties.dataSource.backgroundTrack.clips.count
  }

  /// Stores Combine subscriptions
  var cancellables = Set<AnyCancellable>()

  // MARK: - Life cycle

  init(config: EngineConfiguration, behavior: InteractorBehavior, dismiss: DismissAction) {
    self.config = config
    self.behavior = behavior
    self.dismiss = dismiss
  }

  init(config: EngineConfiguration, behavior: InteractorBehavior, sheet: SheetState?) {
    self.config = config
    self.behavior = behavior
    if let sheet {
      _sheet = .init(initialValue: sheet)
    }
  }

  deinit {
    stateTask?.cancel()
    eventTask?.cancel()
    sceneTask?.cancel()
    zoom.task?.cancel()
    exportTask?.cancel()
    zoomLevelTask?.cancel()
    historyTask?.cancel()
    pageTask?.cancel()
    blockTasks.forEach { $0.value.cancel() }
    blockTasks.removeAll()
  }

  private func onAppear() {
    updateState()
    stateTask = observeState()
    eventTask = observeEvent()
    zoomLevelTask = observeZoomLevel()
    historyTask = observeHistory()
    pageTask = observePage()
    keyboardPublisher.assign(to: &$isKeyboardPresented)
  }

  func onWillDisappear() {
    try? engine?.block.deselectAll()
    sheet.isPresented = false
  }

  func onDisappear() {
    guard !isSystemCameraShown else {
      return
    }
    stateTask?.cancel()
    eventTask?.cancel()
    sceneTask?.cancel()
    zoom.task?.cancel()
    exportTask?.cancel()
    zoomLevelTask?.cancel()
    historyTask?.cancel()
    pageTask?.cancel()
    _engine = nil
    timelineProperties.timeline = nil
    timelineProperties.thumbnailsManager.destroyProviders()
    blockTasks.forEach { $0.value.cancel() }
    blockTasks.removeAll()
  }

  // MARK: - Private properties

  let behavior: InteractorBehavior

  // The optional _engine instance allows to control the deinitialization.
  private var _engine: Engine?

  private var previousEditMode: EditMode?
  var cropSheetTypeEvent: SheetTypes.Crop?
  var exitCropModeAction: (() throws -> Void)?

  private var stateTask: Task<Void, Never>?
  private var eventTask: Task<Void, Never>?
  private var sceneTask: Task<Void, Never>?
  private var zoom: (task: Task<Void, Never>?, toTextCursor: Bool) = (nil, false)
  private var exportTask: Task<Void, Never>?
  private var zoomLevelTask: Task<Void, Never>?
  private var historyTask: Task<Void, Never>?
  private var pageTask: Task<Void, Never>?
  var blockTasks = [BlockID: Task<Void, Never>]()
}

// MARK: - Block queries

extension Interactor {
  private func block<T>(_ id: BlockID?, _ query: (@MainActor (BlockID) throws -> T)?) -> T? {
    guard let engine, let id, engine.block.isValid(id) else {
      return nil
    }
    do {
      return try query?(id)
    } catch {
      handleErrorWithTask(error)
      return nil
    }
  }

  private func isColorFillType(_ id: DesignBlockID?, type: ColorFillType) -> Bool {
    guard let id, let engine else { return false }
    do {
      let fillType: ColorFillType? = try engine.block.get(id, .fill, property: .key(.type))
      return fillType == type
    } catch {
      return false
    }
  }

  func canBringForward(_ id: BlockID?) -> Bool { block(id, engine?.block.canBringForward) ?? false }
  func canBringBackward(_ id: BlockID?) -> Bool { block(id, engine?.block.canBringBackward) ?? false }
  func supportsFill(_ id: BlockID?) -> Bool { block(id, engine?.block.supportsFill) ?? false }
  func supportsStroke(_ id: BlockID?) -> Bool { block(id, engine?.block.supportsStroke) ?? false }
  func supportsBackground(_ id: BlockID?) -> Bool { block(id, engine?.block.supportsBackgroundColor) ?? false }
  func supportsOpacity(_ id: BlockID?) -> Bool { block(id, engine?.block.supportsOpacity) ?? false }
  func supportsBlendMode(_ id: BlockID?) -> Bool { block(id, engine?.block.supportsBlendMode) ?? false }
  func supportsBlur(_ id: BlockID?) -> Bool { block(id, engine?.block.supportsBlur) ?? false }
  func supportsCrop(_ id: BlockID?) -> Bool { block(id, engine?.block.supportsCrop) ?? false }
  func canResetCrop(_ id: BlockID?) -> Bool { block(id, engine?.block.canResetCrop) ?? false }
  func isSolidFill(_ id: DesignBlockID?) -> Bool { isColorFillType(id, type: .solid) }
  func isGradientFill(_ id: DesignBlockID?) -> Bool { isColorFillType(id, type: .gradient) }
  func isColorFill(_ id: DesignBlockID?) -> Bool { isSolidFill(id) || isGradientFill(id) }
  func isVisibleAtCurrentPlaybackTime(_ id: BlockID?) -> Bool {
    block(id, engine?.block.isVisibleAtCurrentPlaybackTime) ?? false
  }
}

// MARK: - Property bindings

extension Interactor {
  /// Create a `TextState` binding for a block `id`.
  /// If `resetFontProperties` is enabled bold and italic states would not be preserved on set.
  func bindTextState(_ id: BlockID?, resetFontProperties: Bool, overrideScopes: Set<Scope> = []) -> Binding<TextState> {
    bind(id, default: TextState()) { engine, block in
      var text = TextState()
      text.assetID = self.fontLibrary.assetFor(typefaceName: try engine.block.getTypeface(block).name)?.id
      text.setFontProperties(try engine.block.getFontProperties(block))
      return text
    } setter: { engine, blocks, text, completion in
      guard let assetID = text.assetID,
            let typeface = self.fontLibrary.typefaceFor(id: assetID) else {
        return false
      }

      func font(typeface: Typeface) -> IMGLYEngine.Font? {
        if resetFontProperties {
          typeface.previewFont
        } else {
          typeface.font(for: .init(bold: text.isBold, italic: text.isItalic)) ?? typeface.previewFont
        }
      }

      if let font = font(typeface: typeface) {
        let changed = try blocks.filter {
          try engine.block.get($0, property: .key(.textFontFileURI)) != font.uri
        }
        try changed.forEach {
          try engine.block.overrideAndRestore($0, scopes: overrideScopes) {
            if resetFontProperties {
              try engine.block.setTypeface($0, typeface: typeface)
            } else {
              try engine.block.setFont($0, fontFileURL: font.uri, typeface: typeface)
            }
          }
        }
        let didChange = !changed.isEmpty
        return try (completion?(engine, blocks, didChange) ?? false) || didChange
      } else {
        return false
      }
    }
  }

  // swiftlint:disable cyclomatic_complexity
  /// Create `SelectionColor` bindings categorized by block names for a given set of `selectionColors`.
  func bind(_ selectionColors: SelectionColors,
            completion: PropertyCompletion? = Completion.addUndoStep) -> [(name: String, colors: [SelectionColor])] {
    selectionColors.sorted.map { name, colors in
      let colors = colors.map { color in
        SelectionColor(color: color, binding: .init {
          // Assume all properties and valid blocks assigned to the selection color still share the same color.
          // Otherwise the first found visible color is returned.
          guard let engine = self.engine, let properties = selectionColors[name, color] else {
            return color
          }

          for (property, blocks) in properties {
            let validBlock = blocks.first { id in
              let isEnabled: Bool = {
                guard let enabledProperty = property.enabled else {
                  return false
                }
                do {
                  return try engine.block.get(id, property: enabledProperty)
                } catch {
                  self.handleErrorWithTask(error)
                  return false
                }
              }()
              return engine.block.isValid(id) && isEnabled
            }

            if let validBlock {
              // If the property is set to solid fill color we need to
              // check for gradient color as well.
              if property == .key(.fillSolidColor), self.isGradientFill(validBlock) {
                if let engine = self.engine, let colorStops: [GradientColorStop] = try? engine.block.get(
                  validBlock,
                  .fill,
                  property: .key(.fillGradientColors)
                ), let color = colorStops.first?.color.cgColor {
                  return color
                }
              } else {
                if let value: CGColor = self.get(validBlock, property: property) {
                  return value
                }
              }
            }
          }

          // No valid block found.
          return color
        } set: { value, _ in
          guard let properties = selectionColors[name, color] else {
            return
          }
          for (property, ids) in properties {
            var gradientIDs: [DesignBlockID] = []
            for id in ids where self.isGradientFill(id) {
              gradientIDs.append(id)
            }
            _ = self.set(gradientIDs, .fill, property: .key(.type), value: ColorFillType.solid, completion: nil)
            _ = self.set(ids, property: property, value: value,
                         setter: Setter.set(overrideScopes: [.key(.fillChange), .key(.strokeChange)]),
                         completion: completion)
          }
        })
      }

      return (name: name, colors: colors)
    }
  }

  // swiftlint:enable cyclomatic_complexity

  /// Create a `property` `Binding` for a block `id`. The `defaultValue` will be used as fallback if the property
  /// cannot be resolved.
  func bind<T: MappedType>(_ id: BlockID?, _ propertyBlock: PropertyBlock? = nil,
                           property: Property, default defaultValue: T,
                           getter: @escaping PropertyGetter<T> = Getter.get(),
                           setter: @escaping PropertySetter<T> = Setter.set(),
                           completion: PropertyCompletion? = Completion.addUndoStep) -> Binding<T> {
    .init {
      guard let id, let value: T = self.get(id, propertyBlock, property: property, getter: getter) else {
        return defaultValue
      }
      return value
    } set: { value, _ in
      guard let id else {
        return
      }
      _ = self.set([id], propertyBlock, property: property, value: value, setter: setter, completion: completion)
    }
  }

  /// Create a propertyless `Binding` for a block `id`. The `defaultValue` will be used as fallback if the property
  /// cannot be resolved.
  func bind<T>(_ id: BlockID?, default defaultValue: T,
               getter: @escaping RawGetter<T>,
               setter: @escaping RawSetter<T>,
               completion: PropertyCompletion? = Completion.addUndoStep) -> Binding<T> {
    .init {
      guard let id, let value: T = self.get(id, getter: getter) else {
        return defaultValue
      }
      return value
    } set: { value, _ in
      guard let id else {
        return
      }
      _ = self.set([id], value: value, setter: setter, completion: completion)
    }
  }

  /// Create a `property` `Binding` for a block `id`. The value `nil` will be used as fallback if the property
  /// cannot be resolved.
  func bind<T: MappedType>(_ id: BlockID?, _ propertyBlock: PropertyBlock? = nil,
                           property: Property,
                           getter: @escaping PropertyGetter<T> = Getter.get(),
                           setter: @escaping PropertySetter<T> = Setter.set(),
                           completion: PropertyCompletion? = Completion.addUndoStep) -> Binding<T?> {
    .init {
      guard let id else {
        return nil
      }
      return self.get(id, propertyBlock, property: property, getter: getter)
    } set: { value, _ in
      guard let value, let id else {
        return
      }
      _ = self.set([id], propertyBlock, property: property, value: value, setter: setter, completion: completion)
    }
  }

  /// Create a propertyless `Binding` for a block `id`. The value `nil` will be used as fallback if the property
  /// cannot be resolved.
  func bind<T>(_ id: BlockID?,
               getter: @escaping RawGetter<T>,
               setter: @escaping RawSetter<T>,
               completion: PropertyCompletion? = Completion.addUndoStep) -> Binding<T?> {
    .init {
      guard let id else {
        return nil
      }
      return self.get(id, getter: getter)
    } set: { value, _ in
      guard let value, let id else {
        return
      }
      _ = self.set([id], value: value, setter: setter, completion: completion)
    }
  }

  func addUndoStep() {
    do {
      try engine?.editor.addUndoStep()
    } catch {
      handleError(error)
    }
  }

  typealias PropertyGetter<T: MappedType> = @MainActor (
    _ engine: Engine,
    _ block: DesignBlockID,
    _ propertyBlock: PropertyBlock?,
    _ property: Property
  ) throws -> T

  typealias RawGetter<T> = @MainActor (
    _ engine: Engine,
    _ block: DesignBlockID
  ) throws -> T

  enum Getter {
    static func get<T: MappedType>() -> Interactor.PropertyGetter<T> {
      { engine, block, propertyBlock, property in
        try engine.block.get(block, propertyBlock, property: property)
      }
    }
  }

  typealias PropertySetter<T: MappedType> = @MainActor (
    _ engine: Engine,
    _ blocks: [DesignBlockID],
    _ propertyBlock: PropertyBlock?,
    _ property: Property,
    _ value: T,
    _ completion: PropertyCompletion?
  ) throws -> Bool

  typealias RawSetter<T> = @MainActor (
    _ engine: Engine,
    _ blocks: [DesignBlockID],
    _ value: T,
    _ completion: PropertyCompletion?
  ) throws -> Bool

  enum Setter {
    static func set<T: MappedType>() -> Interactor.PropertySetter<T> {
      { engine, blocks, propertyBlock, property, value, completion in
        let didChange = try engine.block.set(blocks, propertyBlock, property: property, value: value)
        return try (completion?(engine, blocks, didChange) ?? false) || didChange
      }
    }

    static func set<T: MappedType>(overrideScope: Scope) -> Interactor.PropertySetter<T> {
      set(overrideScopes: [overrideScope])
    }

    static func set<T: MappedType>(overrideScopes: Set<Scope>) -> Interactor.PropertySetter<T> {
      { engine, blocks, propertyBlock, property, value, completion in
        let didChange = try engine.block.overrideAndRestore(blocks, scopes: overrideScopes) {
          try engine.block.set($0, propertyBlock, property: property, value: value)
        }
        return try (completion?(engine, blocks, didChange) ?? false) || didChange
      }
    }
  }

  typealias PropertyCompletion = @MainActor (
    _ engine: Engine,
    _ blocks: [DesignBlockID],
    _ didChange: Bool
  ) throws -> Bool

  enum Completion {
    static let addUndoStep: PropertyCompletion = addUndoStep()

    static func addUndoStep(completion: Interactor.PropertyCompletion? = nil) -> Interactor.PropertyCompletion {
      { engine, blocks, didChange in
        if didChange {
          try engine.editor.addUndoStep()
        }
        return try (completion?(engine, blocks, didChange) ?? false) || didChange
      }
    }

    static func set(_ propertyBlock: PropertyBlock? = nil,
                    property: Property, value: some MappedType,
                    completion: Interactor.PropertyCompletion? = nil) -> Interactor.PropertyCompletion {
      { engine, blocks, didChange in
        let didSet = try engine.block.set(blocks, propertyBlock, property: property, value: value)
        let didChange = didChange || didSet
        return try (completion?(engine, blocks, didChange) ?? false || didChange)
      }
    }
  }

  func enumValues<T>(property: Property) -> [T]
    where T: CaseIterable & RawRepresentable, T.RawValue == String {
    guard let engine else {
      return []
    }
    do {
      return try engine.block.enumValues(property: property)
    } catch {
      handleErrorWithTask(error)
      return []
    }
  }
}

// MARK: - Constraints

extension Interactor {
  func isAllowed(_ id: BlockID?, scope: ScopeKey) -> Bool {
    guard let engine, let id, engine.block.isValid(id) else {
      return false
    }
    do {
      return try engine.block.isAllowedByScope(id, scope: .init(scope))
    } catch {
      handleErrorWithTask(error)
      return false
    }
  }

  func isAllowed(_ id: BlockID?, _ mode: SheetMode) -> Bool {
    switch mode {
    case .selectionColors, .font, .fontSize, .color, .resize:
      true
    case .delete:
      isAllowed(id, Action.delete)
    case .duplicate:
      isAllowed(id, Action.duplicate)
    case .editPage, .addPage:
      true
    case .moveUp:
      isAllowed(id, Action.up)
    case .moveDown:
      isAllowed(id, Action.down)
    }
  }

  func isAllowed(_ id: BlockID?, _ action: Action) -> Bool {
    switch action {
    case .toTop, .up, .down, .toBottom:
      let canReorderTrack = if let id, let clip = timelineProperties.dataSource.findClip(id: id),
                               clip.isInBackgroundTrack || Set([.audio, .voiceOver]).contains(clip.clipType) {
        false
      } else {
        true
      }
      return isAllowed(id, scope: .editorAdd) && canReorderTrack
    case .duplicate:
      return isAllowed(id, scope: .lifecycleDuplicate)
    case .delete:
      return isAllowed(id, scope: .lifecycleDestroy)
    case .page, .addPage: return true
    case .resetCrop, .flipCrop:
      return isAllowed(id, scope: .layerCrop) || isAllowed(id, scope: .layerClipping)
    }
  }
}

// MARK: - AssetLibraryInteractor

extension Interactor: AssetLibraryInteractor {
  @_spi(Internal) public func findAssets(sourceID: String, query: AssetQueryData) async throws -> AssetQueryResult {
    guard let engine else {
      throw Error(errorDescription: "Engine unavailable.")
    }
    return try await engine.asset.findAssets(sourceID: sourceID, query: query)
  }

  @_spi(Internal) public func getGroups(sourceID: String) async throws -> [String] {
    guard let engine else {
      throw Error(errorDescription: "Engine unavailable.")
    }
    return try await engine.asset.getGroups(sourceID: sourceID)
  }

  @_spi(Internal) public func getCredits(sourceID: String) -> AssetCredits? {
    engine?.asset.getCredits(sourceID: sourceID)
  }

  @_spi(Internal) public func getLicense(sourceID: String) -> AssetLicense? {
    engine?.asset.getLicense(sourceID: sourceID)
  }

  @_spi(Internal) public func addAsset(to sourceID: String, asset: AssetDefinition) async throws -> AssetDefinition {
    guard let engine else {
      throw Error(errorDescription: "Engine unavailable.")
    }
    let asset = try await config.callbacks.onUpload(engine, sourceID, asset)
    try engine.asset.addAsset(to: sourceID, asset: asset)
    return asset
  }

  @_spi(Internal) public func uploadAsset(to sourceID: String, asset: AssetUpload) async throws -> AssetResult {
    do {
      let asset = try await Self.uploadAsset(interactor: self, to: sourceID, asset: asset)
      if !isAddingCameraRecording {
        assetTapped(sourceID: sourceID, asset: asset)
      }
      return asset
    } catch {
      handleError(error)
      throw error
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  @_spi(Internal) public func assetTapped(sourceID: String, asset: AssetResult) {
    guard let engine else {
      return
    }
    isAddingAsset = true
    sheet.isPresented = false

    Task(priority: .userInitiated) {
      do {
        if sheet.isReplacing, let id = selection?.blocks.first {
          let oldDuration = try engine.block.getDuration(id)

          // If replacing GIFs/looping videos with non-looping videos
          // we need to set the properties for the fill based on the new\
          // asset. This will be part of the engine later.
          if sceneMode == .video, try engine.block.supportsFill(id) {
            let fillID = try engine.block.getFill(id)
            if try engine.block.supportsPlaybackControl(fillID) {
              if let looping = asset.looping {
                try engine.block.setLooping(fillID, looping: looping)
              } else {
                try engine.block.setLooping(fillID, looping: false)
              }
            }
          }
          if let kind = asset.blockKind {
            try engine.block.setKind(id, kind: kind)
          }

          try await engine.asset.applyToBlock(sourceID: sourceID, assetResult: asset, block: id)
          if sheet.content == .sticker {
            try engine.block.overrideAndRestore(id, scope: .key(.layerCrop)) {
              try engine.block.setContentFillMode($0, mode: .contain)
            }
          }
          if try engine.editor.getRole() == "Adopter" {
            try engine.block.setPlaceholderEnabled(id, enabled: false)
          }
          try engine.editor.addUndoStep()

          // In the future, this may be set by the default implementation.
          if let artist = asset.artist,
             let title = asset.title {
            try engine.block.setMetadata(id, key: "name", value: "\(artist) · \(title)")
          } else if let label = asset.label {
            try engine.block.setMetadata(id, key: "name", value: label)
          }

          var trimID = id
          if try engine.block.supportsFill(id) {
            let fillID = try engine.block.getFill(id)
            let fillType = try engine.block.getType(fillID)
            if fillType == FillType.video.rawValue {
              try await engine.block.forceLoadAVResource(fillID)
              let newFootageDuration = try engine.block.getAVResourceTotalDuration(fillID)
              try engine.block.setDuration(id, duration: min(newFootageDuration, oldDuration))
            }
            trimID = fillID
          } else if try engine.block.getType(id) == BlockType.audio.rawValue {
            try await engine.block.forceLoadAVResource(id)
            let newFootageDuration = try engine.block.getAVResourceTotalDuration(id)
            try engine.block.setDuration(id, duration: min(newFootageDuration, oldDuration))
          }

          // When replacing a block, we need to reset its trim properties.
          if try engine.block.supportsTrim(trimID) {
            try? engine.block.setTrimOffset(trimID, offset: .zero)
            if let newDuration = try? engine.block.getDuration(id) {
              try? engine.block.setTrimLength(trimID, length: newDuration)
            }
          }
        } else {
          let addToBackgroundTrack = sheet.content == .clip

          if let id = try await engine.asset.apply(sourceID: sourceID, assetResult: asset) {
            let pageID = try engine.getPage(page)

            switch sceneMode {
            case .design:
              try engine.block.appendChild(to: pageID, child: id)
              try updateCamera(id)
            case .video:
              // This is a video scene, so we need to take care of offsets and durations
              let minClipDuration: TimeInterval = 1
              let fallbackClipDuration: TimeInterval = 5

              var resolvedDuration = asset.duration ?? fallbackClipDuration

              if addToBackgroundTrack {
                createBackgroundTrackIfNeeded()
                guard let backgroundTrack = timelineProperties.backgroundTrack else {
                  handleError(
                    Error(errorDescription: "No Background Track.")
                  )
                  return
                }
                // Append to background track and configure
                try engine.block.appendChild(to: backgroundTrack, child: id)
                try engine.block.fillParent(id)

                // Make sure to put the playhead on the added track and not slightly before it due to floating-point
                // precision issues.
                let epsilon = 0.0001
                try engine.block.setPlaybackTime(pageID, time: engine.block.getTimeOffset(id) + epsilon)
              } else {
                // Append to page
                try engine.block.appendChild(to: pageID, child: id)

                // Determine where at which point in time to insert the clip
                let playbackTime = try engine.block.getPlaybackTime(pageID)
                let totalDuration = try engine.block.getDuration(pageID)

                // Prevent inserting at the very end of the timeline
                var clampedOffset = max(0, min(playbackTime, totalDuration - minClipDuration))

                if let blockType = try? engine.block.getType(id),
                   blockType == BlockType.audio.rawValue {
                  // Always insert audio at the beginning
                  clampedOffset = 0
                }

                // Set the time offset
                try engine.block.setTimeOffset(id, offset: clampedOffset)

                // If there is nothing in the scene yet, we allow the full asset duration,
                // otherwise shorten to fit remaining time:
                let maxClipDuration = totalDuration - clampedOffset
                let assetDuration = asset.duration ?? max(fallbackClipDuration, maxClipDuration)
                resolvedDuration = totalDuration == 0 ? assetDuration : min(assetDuration, maxClipDuration)
              }

              try engine.block.setDuration(id, duration: resolvedDuration)

              // In the future, this may be set by the default implementation.
              if let artist = asset.artist,
                 let title = asset.title {
                try engine.block.setMetadata(id, key: "name", value: "\(artist) · \(title)")
              } else if let label = asset.label {
                try engine.block.setMetadata(id, key: "name", value: label)
              }

              if try engine.block.supportsFill(id) {
                let fillID = try engine.block.getFill(id)
                let fillType = try engine.block.getType(fillID)
                if fillType == FillType.video.rawValue {
                  // Wait for the video data to load
                  try await engine.block.forceLoadAVResource(fillID)

                  let footageDuration = try engine.block.getAVResourceTotalDuration(fillID)
                  if addToBackgroundTrack {
                    try engine.block.setDuration(id, duration: footageDuration)
                  } else {
                    try engine.block.setDuration(id, duration: min(resolvedDuration, footageDuration))
                  }
                }
              } else if try engine.block.getType(id) == BlockType.audio.rawValue {
                // Prevent audio blocks from being considered in the z-index reordering
                try engine.block.setAlwaysOnTop(id, enabled: true)

                // Wait for the audio data to load
                try await engine.block.forceLoadAVResource(id)

                let footageDuration = try engine.block.getAVResourceTotalDuration(id)
                try engine.block.setDuration(id, duration: min(resolvedDuration, footageDuration))
                try engine.block.setLooping(id, looping: false)
              }
            case .none:
              assertionFailure("Unknown scene mode.")
            @unknown default:
              assertionFailure("Unknown scene mode.")
            }

            if ProcessInfo.isUITesting {
              try engine.block.setPositionX(id, value: 15)
              try engine.block.setPositionY(id, value: 5)
            }
          }
        }
      } catch {
        handleError(error)
      }
      isAddingAsset = false
    }
  }

  private func updateCamera(_ id: DesignBlockID) throws {
    guard let engine else { return }
    let camera = try engine.getCamera()
    let width = try engine.block.getFrameWidth(id)
    let height = try engine.block.getFrameHeight(id)

    let pixelRatio: Float = try engine.block.get(camera, property: .key(.cameraPixelRatio))
    let cameraWidth: Float = try engine.block.get(camera, property: .key(.cameraResolutionWidth)) / pixelRatio
    let cameraHeight: Float = try engine.block.get(camera, property: .key(.cameraResolutionHeight)) / pixelRatio

    let screenRect = CGRect(x: 0, y: 0, width: Int(cameraWidth), height: Int(cameraHeight))
    let pageRect = try engine.block.getScreenSpaceBoundingBox(containing: [engine.getPage(page)])
    let pageWidth = Float(pageRect.width)

    let visiblePageRect = pageRect.intersection(screenRect)
    try engine.block.setPositionXMode(id, mode: .absolute)
    try engine.block.setPositionYMode(id, mode: .absolute)

    let newX = try engine
      .pointToCanvasUnit((visiblePageRect.origin.x - pageRect.origin.x) + visiblePageRect.size.width / 2) - width / 2
    let newY = try engine
      .pointToCanvasUnit((visiblePageRect.origin.y - pageRect.origin.y) + visiblePageRect.size.height / 2) - height / 2
    try engine.block.setPositionX(id, value: newX)
    try engine.block.setPositionY(id, value: newY)

    if pageWidth > cameraWidth {
      try engine.block.scale(id, to: cameraWidth / pageWidth, anchorX: 0.5, anchorY: 0.5)
    }
  }
}

// MARK: - Resizing

extension Interactor {
  func applyResizeAsset(sourceID: String, asset: AssetResult, to id: DesignBlockID?) {
    func resizePages() async throws {
      let pages = try engine?.getSortedPages()
      let scene = try engine?.scene.get()
      if let engine, let pages, let scene {
        // Temporarily disable camera clamping as otherwise the page carousel breaks
        // while resizing as we cannot batch update the sizes for all pages.
        // Do not temporarily disable the page carousel because this leads to
        // visual bugs. It will be reapplied with the next zoom update.
        try disableCameraClamping()

        await withThrowingTaskGroup(of: Void.self) { group in
          for page in pages {
            group.addTask {
              try await engine.asset.applyToBlock(sourceID: sourceID, assetResult: asset, block: page)
            }
          }
        }

        switch asset.payload?.transformPreset {
        case let .fixedSize(width, height, designUnit):
          let dpi: Float = designUnit == .px ? 72 : 300
          try engine.block.setFloat(scene, property: "scene/pageDimensions/width", value: width)
          try engine.block.setFloat(scene, property: "scene/pageDimensions/height", value: height)
          try engine.block.setFloat(scene, property: "scene/dpi", value: dpi)
        case .fixedAspectRatio:
          if let id {
            let width = try engine.block.getWidth(id)
            let height = try engine.block.getHeight(id)
            try engine.block.setFloat(scene, property: "scene/pageDimensions/width", value: width)
            try engine.block.setFloat(scene, property: "scene/pageDimensions/height", value: height)
          }
        default: break
        }

        updateZoom(
          for: .pageSizeChanged,
          with: (zoomModel.defaultInsets, zoomModel.canvasHeight, zoomModel.padding)
        )
      }
    }

    Task(priority: .userInitiated) {
      do {
        if let id, let type = try engine?.block.getType(id) {
          if type == DesignBlockType.page.rawValue {
            try await resizePages()
          } else {
            try await engine?.asset.applyToBlock(sourceID: sourceID, assetResult: asset, block: id)
          }
        } else {
          try await resizePages()
        }
        try engine?.editor.addUndoStep()
      } catch {
        handleError(error)
      }
    }
  }

  func resizePages(width: CGFloat, height: CGFloat, designUnit: DesignUnit, dpi: CGFloat, pixelScale: CGFloat) throws {
    guard let pages = try engine?.getSortedPages(), let scene = try engine?.scene.get() else { return }
    // Temporarily disable camera clamping as otherwise the page carousel breaks
    // while resizing as we cannot batch update the sizes for all pages.
    // Do not temporarily disable the page carousel because this leads to
    // visual bugs. It will be reapplied with the next zoom update.
    try disableCameraClamping()

    try engine?.scene.setDesignUnit(designUnit)
    try engine?.block.setFloat(scene, property: "scene/pixelScaleFactor", value: Float(pixelScale))
    try engine?.block.setFloat(scene, property: "scene/dpi", value: Float(dpi))
    try engine?.block.setFloat(scene, property: "scene/pageDimensions/width", value: Float(width))
    try engine?.block.setFloat(scene, property: "scene/pageDimensions/height", value: Float(height))
    try engine?.block.resizeContentAware(pages, width: Float(width), height: Float(height))

    updateZoom(for: .pageSizeChanged, with: (zoomModel.defaultInsets, zoomModel.canvasHeight, zoomModel.padding))
    try engine?.editor.addUndoStep()
  }

  private func disableCameraClamping() throws {
    guard let engine else { return }
    let scene = try engine.getScene()
    if try engine.scene.unstable_isCameraZoomClampingEnabled(scene) {
      try engine.scene.unstable_disableCameraZoomClamping()
    }
    if try engine.scene.unstable_isCameraPositionClampingEnabled(scene) {
      try engine.scene.unstable_disableCameraPositionClamping()
    }
  }
}

// MARK: - Actions

extension Interactor {
  func sheetDismissButtonTapped() {
    sheet.isPresented = false
  }

  func bottomBarCloseButtonTapped() {
    do {
      try engine?.block.deselectAll()
    } catch {
      handleError(error)
    }
  }

  func keyboardBarDismissButtonTapped() {
    setEditMode(.transform)
  }

  // swiftlint:disable:next cyclomatic_complexity
  func bottomBarButtonTapped(for mode: SheetMode) {
    pause()

    // For certain sheets we want to guarantee that the selected clip is visible at the current playback time.
    if ![
      .delete,
    ].contains(mode) {
      clampPlayheadPositionToSelectedClip()
    }

    do {
      switch mode {
      case .selectionColors:
        sheet.commit { model in
          model = .init(mode)
        }
      case .font:
        sheet.commit { model in
          model = .init(mode)
        }
      case .fontSize:
        sheet.commit { model in
          model = .init(mode, style: .only(detent: .imgly.tiny))
        }
      case .color:
        sheet.commit { model in
          model = .init(mode, style: .only(detent: .imgly.tiny))
        }
      case .delete:
        if isPagesMode {
          if let currentPage = pageOverview.currentPage {
            try engine?.delete([currentPage])
          }
        } else {
          try engine?.deleteSelectedElement(delay: NSEC_PER_MSEC * 200)
        }
      case .duplicate:
        if isPagesMode {
          if let currentPage = pageOverview.currentPage {
            try engine?.duplicate([currentPage])
          }
        } else {
          try engine?.duplicateSelectedElement()
        }
      case .editPage:
        viewMode = .edit
      case .addPage:
        try engine?.addPage(page + 1)
      case .moveUp:
        if isPagesMode {
          if let currentPage = pageOverview.currentPage {
            try engine?.sendBackward([currentPage])
          }
        } else {
          try engine?.bringForwardSelectedElement()
        }
      case .moveDown:
        if isPagesMode {
          if let currentPage = pageOverview.currentPage {
            try engine?.bringForward([currentPage])
          }
        } else {
          try engine?.sendBackwardSelectedElement()
        }
      case .resize:
        sheet.commit { model in
          model = .init(mode, style: .only(detent: .imgly.small))
        }
      }
    } catch {
      handleError(error)
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  @_spi(Internal) public func actionButtonTapped(for action: Action) {
    do {
      switch action {
      case .toTop: try engine?.bringToFrontSelectedElement()
      case .up: try engine?.bringForwardSelectedElement()
      case .down: try engine?.sendBackwardSelectedElement()
      case .toBottom: try engine?.sendToBackSelectedElement()
      case .duplicate: try engine?.duplicateSelectedElement()
      case .delete: try engine?.deleteSelectedElement(delay: NSEC_PER_MSEC * 200)
      case let .page(index): try setPage(index)
      case let .addPage(index): try engine?.addPage(index)
      case .resetCrop: try engine?.resetCropSelectedElement()
      case .flipCrop: try engine?.flipCropSelectedElement()
      }
    } catch {
      handleError(error)
    }
  }

  func loadScene(with insets: EdgeInsets?) {
    guard sceneTask == nil else {
      return
    }
    zoomModel.defaultInsets = insets ?? EdgeInsets()

    sceneTask = Task {
      do {
        let engine = try await Engine(license: config.settings.license, userID: config.settings.userID)
        _engine = engine
        onAppear()

        try await behavior.loadScene(.init(engine, self), with: insets)
        try await fontLibrary.loadFromAssetSource(engine: engine, sourceID: Engine.DefaultAssetSource.typeface.rawValue)

        try configureTimeline()
        self.zoomLevelChanged(forceUpdate: true)

        // Reset history only once after onCreate!
        try engine.editor.resetHistory()
      } catch {
        handleErrorAndDismiss(error)
      }
    }
  }

  func cancelExport() {
    exportTask?.cancel()
  }

  private func getContext(_ action: (@MainActor (_ context: InteractorContext) throws -> Void)?) rethrows {
    guard let engine else {
      return
    }
    try action?(.init(engine, self))
  }

  // MARK: - Zoom

  // swiftlint:disable:next large_tuple
  func updateZoom(for event: ZoomEvent, with zoom: (zoomPadding: CGFloat,
                                                    canvasGeometry: Geometry?,
                                                    sheetGeometry: Geometry?,
                                                    layoutDirection: LayoutDirection?)) {
    let zoomParameters = zoomParameters(
      zoomPadding: zoom.zoomPadding,
      canvasGeometry: zoom.canvasGeometry,
      sheetGeometry: zoom.sheetGeometry,
      layoutDirection: zoom.layoutDirection ?? .leftToRight
    )
    updateZoom(for: event, with: zoomParameters)
  }

  private func updateZoom(for event: ZoomEvent,
                          // swiftlint:disable:next large_tuple
                          with zoom: (insets: EdgeInsets?, canvasHeight: CGFloat, padding: CGFloat)) {
    if zoomModel.defaultPadding != zoom.padding {
      zoomModel.defaultPadding = zoom.padding
    }
    if zoomModel.canvasHeight != zoom.canvasHeight {
      zoomModel.canvasHeight = zoom.canvasHeight
    }
    switch event {
    case .pageSizeChanged:
      updateZoom(with: zoom.insets, canvasHeight: zoom.canvasHeight, zoomToPage: true)
    case .canvasGeometryChanged:
      zoomModel.defaultInsets = zoom.insets ?? EdgeInsets()
      updateZoom(
        with: zoom.insets,
        canvasHeight: zoom.canvasHeight,
        zoomToPage: previousEditMode != .text
      )
    case .pageChanged:
      let pageIndex = try? engine?.getCurrentPageIndex()
      if let pageIndex, pageIndex != page {
        updateZoom(with: zoom.insets, canvasHeight: zoom.canvasHeight, zoomToPage: true)
      }
    case .sheetGeometryChanged:
      updateZoom(with: zoom.insets, canvasHeight: zoom.canvasHeight)
    case .sheetClosed:
      // Reset zoom insets because they could have been overwritten by canvas geometry changes
      // (e.g. triggered by device orientation changes or keyboard) while sheet was open and
      // potentially floating (without affecting zoom).
      zoomModel.defaultInsets = zoom.insets ?? EdgeInsets()
      updateZoom(
        with: zoom.insets,
        canvasHeight: zoom.canvasHeight,
        clampOnly: sheet.isFloating
      )
    case let .textCursorChanged(value):
      zoomToText(with: zoom.insets, canvasHeight: zoom.canvasHeight, cursorPosition: value)
    }
  }

  @_spi(Internal) public func zoomToPage(withAdditionalPadding padding: CGFloat) {
    zoomModel.padding = padding
    updateZoom(zoomToPage: true)
  }

  private func updateZoom(
    with insets: EdgeInsets? = nil,
    canvasHeight: CGFloat = 0,
    zoomToPage: Bool = false,
    clampOnly: Bool = false
  ) {
    let lastTask = zoom.task
    lastTask?.cancel()

    zoom.toTextCursor = false
    zoom.task = Task {
      _ = await sceneTask?.result
      _ = await lastTask?.result
      if Task.isCancelled {
        return
      }
      do {
        if !isPreviewMode {
          if sheet.isFloating, sheet.isPresented { return }
          let zoomLevel: Float? = if zoomToPage {
            try await engine?.zoomToPage(page, insets, zoomModel: zoomModel)
          } else {
            try await engine?.updateZoom(
              with: insets,
              and: canvasHeight,
              clampOnly: clampOnly,
              pageIndex: page,
              zoomModel: zoomModel
            )
          }
          if let zoomLevel {
            zoomModel.defaultZoomLevel = zoomLevel
          }
          if editMode == .text {
            try engine?.zoomToSelectedText(insets, canvasHeight: canvasHeight)
          }
        } else {
          guard let engine else { return }
          try await behavior.enablePreviewMode(.init(engine, self), insets)
        }
        if isCreating {
          // Wait a moment to be sure that the engine rendered the first intended frame after initial zooming before
          // presenting the canvas even on low-end devices (iPhone X).
          try await Task.sleep(for: .milliseconds(100))
          isCreating = false
        }
      } catch {
        handleError(error)
      }
    }
  }

  func zoomToText(with insets: EdgeInsets?, canvasHeight: CGFloat, cursorPosition: CGPoint?) {
    guard editMode == .text, let cursorPosition, cursorPosition != .zero else {
      return
    }

    let lastTask = zoom.task
    if zoom.toTextCursor {
      lastTask?.cancel()
    }

    zoom.toTextCursor = true
    zoom.task = Task {
      _ = await sceneTask?.result
      _ = await lastTask?.result
      if Task.isCancelled {
        return
      }
      do {
        try engine?.zoomToSelectedText(insets, canvasHeight: canvasHeight)
      } catch {
        handleError(error)
      }
    }
  }

  func zoomParameters(
    zoomPadding: CGFloat,
    canvasGeometry: Geometry?,
    sheetGeometry: Geometry?,
    layoutDirection: LayoutDirection = .leftToRight
    // swiftlint:disable:next large_tuple
  ) -> (insets: EdgeInsets?, canvasHeight: CGFloat, padding: CGFloat) {
    let canvasHeight = canvasGeometry?.size.height ?? 0

    let insets: EdgeInsets?
    if let sheetGeometry, let canvasGeometry {
      var sheetInsets = canvasGeometry.safeAreaInsets
      let height = canvasGeometry.size.height
      let sheetMinY = sheetGeometry.frame.minY - sheetGeometry.safeAreaInsets.top
      sheetInsets.bottom = max(sheetInsets.bottom, zoomPadding + height - sheetMinY)
      sheetInsets.bottom = min(sheetInsets.bottom, height * 0.7)
      insets = sheetInsets
    } else {
      insets = canvasGeometry?.safeAreaInsets
    }

    if var rtl = insets, layoutDirection == .rightToLeft {
      swap(&rtl.leading, &rtl.trailing)
      return (rtl, canvasHeight, zoomPadding)
    }

    return (insets, canvasHeight, zoomPadding)
  }
}

// MARK: - Private implementation

extension Interactor {
  var engine: Engine? {
    guard let engine = _engine else {
      return nil
    }
    return engine
  }

  func handleError(_ error: Swift.Error) {
    self.error = .init(error, dismiss: false)
  }

  func handleErrorWithTask(_ error: Swift.Error) {
    // Only show most recent error once.
    if error.localizedDescription != self.error.details?.message {
      Task {
        handleError(error)
      }
    }
  }

  func handleErrorAndDismiss(_ error: Swift.Error) {
    self.error = .init(error, dismiss: true)
  }

  func get<T: MappedType>(_ id: DesignBlockID, _ propertyBlock: PropertyBlock? = nil,
                          property: Property,
                          getter: PropertyGetter<T> = Getter.get()) -> T? {
    guard let engine, engine.block.isValid(id) else {
      return nil
    }
    do {
      return try getter(engine, id, propertyBlock, property)
    } catch {
      handleErrorWithTask(error)
      return nil
    }
  }

  func get<T>(_ id: DesignBlockID,
              getter: RawGetter<T>) -> T? {
    guard let engine, engine.block.isValid(id) else {
      return nil
    }
    do {
      return try getter(engine, id)
    } catch {
      handleErrorWithTask(error)
      return nil
    }
  }

  func set<T: MappedType>(_ ids: [DesignBlockID], _ propertyBlock: PropertyBlock? = nil,
                          property: Property, value: T,
                          setter: PropertySetter<T> = Setter.set(),
                          completion: PropertyCompletion?) -> Bool {
    guard let engine else {
      return false
    }
    do {
      let valid = ids.filter {
        engine.block.isValid($0)
      }
      return try setter(engine, valid, propertyBlock, property, value, completion)
    } catch {
      handleErrorWithTask(error)
      return false
    }
  }

  func set<T>(_ ids: [DesignBlockID],
              value: T,
              setter: RawSetter<T>,
              completion: PropertyCompletion?) -> Bool {
    guard let engine else {
      return false
    }
    do {
      let valid = ids.filter {
        engine.block.isValid($0)
      }
      return try setter(engine, valid, value, completion)
    } catch {
      handleErrorWithTask(error)
      return false
    }
  }

  func enablePreviewMode() throws {
    // Workaround as long as roles are present:
    // Currently, the global scopes only apply to the "Creator" role so we
    // temporarly switch to the "Creator" role to prevent selection of blocks.
    try engine?.editor.setGlobalScope(key: ScopeKey.editorSelect.rawValue, value: .deny)
    try engine?.editor.setRoleButPreserveGlobalScopes("Creator")
    // Call engine?.enablePreviewMode() in updateZoom to avoid page fill flickering.
    viewMode = .preview
    sheet.isPresented = false
    setEditMode(.transform)
  }

  func enableEditMode() throws {
    if viewMode == .preview {
      // Workaround as long as roles are present:
      // Currently, the global scopes only apply to the "Creator" role so we
      // temporarly switch to the "Creator" role to prevent selection of blocks.
      try engine?.editor.setGlobalScope(key: ScopeKey.editorSelect.rawValue, value: .defer)
      try engine?.editor.setRoleButPreserveGlobalScopes("Adopter")
      try getContext(behavior.enableEditMode)
    }
    viewMode = .edit
    sheet.isPresented = false
  }

  func enablePagesMode() throws {
    try engine?.block.deselectAll()
    viewMode = .pages
    sheet.isPresented = false
  }

  func exportScene() {
    pause()
    let lastTask = exportTask
    lastTask?.cancel()
    isExporting = true
    exportTask = Task(priority: .userInitiated) {
      _ = await lastTask?.result
      if Task.isCancelled {
        return
      }
      guard let engine else {
        return
      }
      do {
        try await behavior.exportScene(.init(engine, self))
      } catch is CancellationError {
        hideExportSheet()
      } catch {
        if export.isPresented {
          showExportSheet(.error(error) { [weak self] in
            self?.hideExportSheet()
          })
        } else {
          handleError(error)
        }
      }
      isExporting = false
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  func sheetContent(for designBlockType: String, with fillType: String? = nil,
                    and kind: BlockKind? = nil) -> SheetContent? {
    switch designBlockType {
    case BlockType.text.rawValue: return .text
    case BlockType.group.rawValue: return .group
    case BlockType.page.rawValue: return .page
    case BlockType.audio.rawValue:
      if kind == .key(.voiceover) {
        return .voiceover
      }
      return .audio
    case BlockType.graphic.rawValue:
      guard let fillType else { return nil }
      switch fillType {
      case FillType.image.rawValue:
        if kind == .key(.sticker) {
          return .sticker
        }
        return .image
      case FillType.video.rawValue:
        if kind == .key(.animatedSticker) {
          return .sticker
        }
        return .video
      case FillType.color.rawValue,
           FillType.linearGradient.rawValue,
           FillType.conicalGradient.rawValue,
           FillType.radialGradient.rawValue:
        return .shape
      default:
        if kind == .key(.shape) {
          return .shape
        }
        return nil
      }
    default: return nil
    }
  }

  func sheetContent(for selection: Selection?) -> SheetContent? {
    if let selection, selection.blocks.count == 1,
       let block = selection.blocks.first,
       let content = sheetContent(block) {
      return content
    }
    return nil
  }

  func placeholderContent(for selection: Selection?) -> SheetContent? {
    guard let engine,
          let selection, selection.blocks.count == 1,
          let block = selection.blocks.first,
          let content = sheetContent(block) else {
      return nil
    }
    do {
      guard try engine.editor.getRole() == "Adopter",
            try engine.block.supportsPlaceholderControls(block) else {
        return nil
      }
      let isPlaceholder = try engine.block.isPlaceholderEnabled(block)
      let showsPlaceholderButton = try engine.block.isPlaceholderControlsButtonEnabled(block)
      let showsPlaceholderOverlay = try engine.block.isPlaceholderControlsOverlayEnabled(block)

      if isPlaceholder, showsPlaceholderButton || showsPlaceholderOverlay {
        return content
      } else {
        return nil
      }
    } catch {
      handleError(error)
      return nil
    }
  }

  func updateState(_ events: [BlockEvent] = []) {
    guard let engine else {
      return
    }

    let editMode = engine.editor.getEditMode()
    if self.editMode != editMode {
      self.editMode = editMode
    }

    let textCursorPosition = CGPoint(x: CGFloat(engine.editor.getTextCursorPositionInScreenSpaceX()),
                                     y: CGFloat(engine.editor.getTextCursorPositionInScreenSpaceY()))

    if self.textCursorPosition != textCursorPosition {
      self.textCursorPosition = textCursorPosition
    }

    let selected = engine.block.findAllSelected()
    let selection: Selection? = {
      if selected.isEmpty {
        return nil
      } else {
        let box = try? engine.block.getScreenSpaceBoundingBox(containing: selected)
        return .init(blocks: selected, boundingBox: box ?? .zero)
      }
    }()
    let selectedBlockChanged = events.contains { event in
      event.type == .updated && selected.contains { $0 == event.block }
    }

    if self.selection != selection || selectedBlockChanged {
      // Force updating the published property if "something" changed for the selected block
      // to trigger `Interactor.objectWillChange` and thus updating all views that depend on the interactor.
      // This in turn will trigger to update any binding created with `Interactor.bind`.
      self.selection = selection
    }

    if sceneMode == .video,
       let currentPage = timelineProperties.currentPage {
      let isSelectionVisible = isVisibleAtCurrentPlaybackTime(selection?.blocks.first)
      if self.isSelectionVisible != isSelectionVisible {
        self.isSelectionVisible = isSelectionVisible
      }
      do {
        let isLoopingPlaybackEnabled = try engine.block.isLooping(currentPage)
        if self.isLoopingPlaybackEnabled != isLoopingPlaybackEnabled {
          self.isLoopingPlaybackEnabled = isLoopingPlaybackEnabled
        }
      } catch {
        handleError(error)
      }
    }

    do {
      try behavior.updateState(.init(engine, self))
    } catch {
      handleErrorWithTask(error)
    }
  }

  func observeState() -> Task<Void, Never> {
    Task {
      guard let engine else {
        return
      }
      for await _ in engine.editor.onStateChanged {
        updateState()
      }
    }
  }

  func observeEvent() -> Task<Void, Never> {
    Task {
      guard let engine else {
        return
      }
      for await events in engine.event.subscribe(to: []) {
        updateState(events)
        updateTimeline(events)
        updatePlaybackState()
      }
    }
  }

  func observeZoomLevel() -> Task<Void, Never> {
    Task {
      guard let engine else {
        return
      }
      for await _ in engine.scene.onZoomLevelChanged {
        zoomLevelChanged()
      }
    }
  }

  func observeHistory() -> Task<Void, Never> {
    Task {
      guard let engine else {
        return
      }
      for await _ in engine.editor.onHistoryUpdated {
        historyChanged()
        DispatchQueue.main.async { [weak self] in
          self?.refreshThumbnails()
        }
      }
    }
  }

  func observePage() -> Task<Void, Never> {
    Task {
      guard let engine else {
        return
      }
      for await page in engine.scene.onCarouselPageChanged {
        let pageIndex = try? engine.getPageIndex(page)
        if !isCreating, !isPagesMode, let pageIndex, pageIndex != self.page {
          self.page = pageIndex
        }
      }
    }
  }

  func setEditMode(_ newValue: EditMode) {
    guard newValue != editMode else {
      return
    }
    previousEditMode = editMode
    engine?.editor.setEditMode(newValue)
  }

  func setPage(_ newValue: Int) throws {
    guard newValue != page, let engine else {
      return
    }
    let pages = try engine.getSortedPages()
    if (0 ..< pages.endIndex).contains(newValue) {
      page = newValue
    }
  }

  // MARK: - State changes

  func pageChanged(_ oldValue: Int) {
    guard let engine, oldValue != page else {
      return
    }
    do {
      let currentPage = try engine.getPage(page)
      if pageOverview.currentPage != currentPage {
        pageOverview.currentPage = currentPage
      }
      try behavior.pageChanged(.init(engine, self))
      sheet.isPresented = false
    } catch {
      handleError(error)
    }
  }

  func pageOverviewChanged(_ oldValue: PageOverviewState) {
    guard let engine, oldValue != pageOverview, isPagesMode else {
      return
    }
    do {
      // Apply new page ordering to engine
      let currentPages = pageOverview.pages.map(\.block)
      if oldValue.pages.map(\.block) != currentPages,
         try engine.getSortedPages() != currentPages,
         let firstPage = currentPages.first,
         let parent = try engine.block.getParent(firstPage) {
        for (index, page) in currentPages.enumerated() {
          try engine.block.insertChild(into: parent, child: page, at: index)
        }
        // Make sure that current page stays selected
        if let currentPage = pageOverview.currentPage {
          page = try engine.getPageIndex(currentPage)
        }
      } else if oldValue.currentPage != pageOverview.currentPage,
                let currentPage = pageOverview.currentPage {
        page = try engine.getPageIndex(currentPage)
      }
    } catch {
      handleError(error)
    }
  }

  func sheetChanged(_ oldValue: SheetState) {
    guard oldValue != sheet else {
      return
    }
    if !sheet.isPresented, oldValue.isPresented, oldValue.type is SheetTypes.Crop {
      setEditMode(.transform)
    }
  }

  func selectionChanged(_ oldValue: Selection?) {
    guard !isCreating, oldValue != selection else {
      return
    }
    if selection?.blocks.isEmpty ?? true, !isPreviewMode {
      updateZoom(clampOnly: true)
    }

    let wasPresented = sheet.isPresented

    if sheet.isPresented {
      if !(sheet.type is SheetTypes.LibraryAdd),
         oldValue?.blocks != selection?.blocks {
        sheet.isPresented = false
      }
      if sheet.type is SheetTypes.LibraryAdd, selection != nil {
        sheet.isPresented = false
      }
    }
    if oldValue?.blocks != selection?.blocks,
       let content = placeholderContent(for: selection) {
      func showReplaceSheet() {
        sheet = .init(.libraryReplace {
          AssetLibrarySheet(content: content)
        }, content)
      }

      if wasPresented, !sheet.isReplacing, sheet.content != content {
        if sheet.isPresented {
          sheet.isPresented = false
        }
        Task {
          try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 200)
          showReplaceSheet()
        }
      } else {
        showReplaceSheet()
      }
    }

    updateTimelineSelectionFromCanvas()
  }

  func editModeChanged(_ oldValue: EditMode) {
    guard oldValue != editMode else {
      return
    }

    if editMode == .crop {
      // Remember the pinchAction setting …
      defaultPinchAction = (try? engine?.editor.getSettingEnum("touch/pinchAction")) ?? "Zoom"
      try? engine?.editor.setSettingEnum("touch/pinchAction", value: "Scale")
    } else if oldValue == .crop {
      // … to restore it correctly when leaving crop mode.
      try? engine?.editor.setSettingEnum("touch/pinchAction", value: defaultPinchAction)
    }

    if sheet.isPresented {
      if editMode == .text || oldValue == .crop {
        sheet.isPresented = false
      }
    }
    if editMode == .crop, !(sheet.isPresented && sheet.type is SheetTypes.Crop) {
      func showCropSheet() {
        do {
          let sheetType = try cropSheetTypeEvent ?? .crop(id: nonNil(selection?.blocks.first))
          sheet = .init(sheetType, .image)
        } catch {
          handleError(error)
        }
      }

      if sheet.isPresented {
        sheet.isPresented = false
        Task {
          try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 200)
          showCropSheet()
        }
      } else {
        showCropSheet()
      }
    }
    if oldValue == .crop {
      if let exitCropModeAction {
        do {
          try exitCropModeAction()
        } catch {
          handleError(error)
        }
        self.exitCropModeAction = nil
      }
      cropSheetTypeEvent = nil
    }
  }

  func zoomLevelChanged(_ zoom: Float? = nil, forceUpdate: Bool = false) {
    guard !isCreating || forceUpdate else { return }
    if let engine, let zoomLevel = try? engine.scene.getZoom() {
      let sceneZoom = (zoom ?? zoomModel.defaultZoomLevel)
      isDefaultZoomLevel = sceneZoom == nil || sceneZoom == zoomLevel
    }
  }

  func historyChanged() {
    guard let engine else { return }
    do {
      // If in page crop/resize mode, zoom to page again.
      if editMode == .crop, let selection = selection?.blocks.first, let type = try? engine.block.getType(selection),
         type != DesignBlockType.graphic.rawValue {
        updateZoom(for: .pageSizeChanged, with: (zoomModel.defaultInsets, zoomModel.canvasHeight, zoomModel.padding))
      }
      if isPagesMode {
        try pageOverview.update(from: engine)
      } else {
        pageOverview = try .init(from: engine)
      }
    } catch {
      handleError(error)
    }
    guard !isCreating else { return }
    if isPagesMode {
      if let currentPage = pageOverview.currentPage,
         let pageIndex = try? engine.getPageIndex(currentPage) {
        page = pageIndex
      }
    } else {
      let pageIndex = try? engine.getCurrentPageIndex()
      if let pageIndex, pageIndex != page {
        page = pageIndex
      }
    }
    let canUndo = (try? engine.editor.canUndo()) ?? false
    self.canUndo = canUndo // Keep this as it is used to trigger UI updates
    let canRedo = (try? engine.editor.canRedo()) ?? false
    self.canRedo = canRedo // Keep this as it is used to trigger UI updates
    do {
      try behavior.historyChanged(.init(engine, self))
    } catch {
      handleError(error)
    }
  }
}

// Keep extension private or move to IMGLYCore(UI) with all dependencies.
// IMGLYUI engine extensions should always require `@_spi(Internal) import IMGLYCore(UI)`
// to easily separate them from "official" IMGLYEngine code.
private extension Engine {
  func set(_ ids: [DesignBlockID], _ propertyBlock: PropertyBlock? = nil,
           property: Property, value: some MappedType,
           completion: Interactor.PropertyCompletion? = Interactor.Completion.addUndoStep) throws -> Bool {
    let valid = ids.filter {
      block.isValid($0)
    }
    let didChange = try block.set(valid, propertyBlock, property: property, value: value)
    return try (completion?(self, valid, didChange) ?? false) || didChange
  }
}

@MainActor
extension PageOverviewState {
  init(from engine: Engine) throws {
    currentPage = try engine.scene.getCurrentPage()
    pages = try engine.getSortedPages().map {
      .init(uuid: try engine.block.getUUID($0),
            block: $0,
            width: CGFloat(try engine.block.getFrameWidth($0)),
            height: CGFloat(try engine.block.getFrameHeight($0)),
            // When engine exposes the page(s) changed for `onHistoryUpdated` we can selectively refresh pages instead
            // of all.
            refresh: UUID())
    }
  }

  mutating func update(from engine: Engine) throws {
    let new = try Self(from: engine)
    let nextPage = nextPage
    let previousPage = previousPage
    // 1. Pick any new page first
    // 2. If no new page, pick same page as before
    // 3. If that page is gone, try to pick the next page
    // 4. If next page is not available, pick the previous page (guaranteed to exist)
    // 5. Just pick new first page
    let newSelectedPage = new.pages.first { newPage in pages.allSatisfy { $0.block != newPage.block } }
      ?? new.pages.first { $0.block == currentPage }
      ?? new.pages.first { $0.block == nextPage?.block }
      ?? new.pages.first { $0.block == previousPage?.block }
      ?? new.pages.first
    self = .init(currentPage: newSelectedPage?.block, pages: new.pages)
  }

  private var currentPageIndex: Int? {
    pages.firstIndex { $0.block == currentPage }
  }

  private func getPage(_ index: Int) -> Page? {
    guard pages.indices.contains(index) else {
      return nil
    }
    return pages[index]
  }

  private var nextPage: Page? {
    guard let currentPageIndex else {
      return nil
    }
    return getPage(currentPageIndex + 1)
  }

  private var previousPage: Page? {
    guard let currentPageIndex else {
      return nil
    }
    return getPage(currentPageIndex - 1)
  }
}
