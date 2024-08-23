@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYEditor
import IMGLYEngine
import SwiftUI

final class PhotoInteractorBehavior: InteractorBehavior {
  func loadScene(_ context: InteractorContext, with insets: EdgeInsets?) async throws {
    try await DefaultInteractorBehavior.default.loadScene(context, with: insets)

    let page = try context.engine.getSinglePage()

    try context.engine.block.setScopeEnabled(page, scope: .key(.editorSelect), enabled: false)
    try context.engine.block.setScopeEnabled(page, scope: .key(.layerMove), enabled: false)
    try context.engine.block.setScopeEnabled(page, scope: .key(.layerResize), enabled: false)
    try context.engine.block.setScopeEnabled(page, scope: .key(.layerRotate), enabled: false)

    try context.engine.editor.setSettingBool("page/allowCropInteraction", value: true)
    try context.engine.editor.setSettingBool("page/allowMoveInteraction", value: false)
    try context.engine.editor.setSettingBool("page/allowResizeInteraction", value: false)
    try context.engine.editor.setSettingBool("page/allowRotateInteraction", value: false)
  }

  func isBottomBarEnabled(_ context: InteractorContext) throws -> Bool {
    let selected = context.engine.block.findAllSelected()
    guard let block = selected.first, selected.count == 1 else {
      return false
    }
    return try context.engine.block.getType(block) != DesignBlockType.page.rawValue
  }

  func rootBottomBarItems(_ context: InteractorContext) throws -> [RootBottomBarItem] {
    let page = try context.engine.getSinglePage()
    func isAllowed(_ scope: ScopeKey) throws -> Bool {
      try context.engine.block.isAllowedByScope(page, scope: .key(scope))
    }
    var items = [RootBottomBarItem]()

    if try isAllowed(.appearanceAdjustments) {
      items += [.adjustments(page)]
    }
    if try isAllowed(.appearanceFilter) {
      items += [.filter(page)]
    }
    if try isAllowed(.appearanceEffect) {
      items += [.effect(page)]
    }
    if try isAllowed(.appearanceBlur) {
      items += [.blur(page)]
    }
    if try isAllowed(.layerCrop) {
      items += [
        .crop(page, enter: .init {
          context.interactor.zoomToPage(withAdditionalPadding: 24)
        }, exit: .init {
          context.interactor.zoomToPage(withAdditionalPadding: 0)
          try context.engine.block.setSelected(page, selected: false)
        }),
      ]
    }
    items += [
      .addText,
      .addShape,
      .addSticker,
    ]
    return items
  }

  func historyChanged(_ context: InteractorContext) throws {
    let page = try context.engine.getSinglePage(withImageFill: false)
    if try context.engine.block.isSelected(page), context.engine.editor.getEditMode() != .crop {
      try context.engine.block.setSelected(page, selected: false)
    }
  }
}

extension InteractorBehavior where Self == PhotoInteractorBehavior {
  static var photo: Self { Self() }
}

private extension Engine {
  func getSinglePage(withImageFill: Bool = true) throws -> DesignBlockID {
    let pages = try scene.getPages()
    guard let page = pages.first, pages.count == 1 else {
      throw Error(errorDescription: "Single page required.")
    }
    if withImageFill {
      guard try block.getType(block.getFill(page)) == FillType.image.rawValue else {
        throw Error(errorDescription: "Single page with image fill required.")
      }
    }
    return page
  }
}
