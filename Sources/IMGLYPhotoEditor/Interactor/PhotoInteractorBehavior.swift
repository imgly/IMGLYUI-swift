@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYEditor
import IMGLYEngine
import SwiftUI

final class PhotoInteractorBehavior: InteractorBehavior {
  func loadScene(_ context: InteractorContext, with insets: EdgeInsets?) async throws {
    try await DefaultInteractorBehavior.default.loadScene(context, with: insets)

    let page = try context.engine.getSinglePage()

    // Disable this for the initial state.
    try context.engine.editor.setHighlightingEnabled(page, enabled: false)
    try context.engine.block.setScopeEnabled(page, scope: .key(.layerResize), enabled: false)
    try context.engine.block.setScopeEnabled(page, scope: .key(.editorSelect), enabled: true)
    try context.engine.block.setScopeEnabled(page, scope: .key(.layerMove), enabled: false)
    try context.engine.block.setScopeEnabled(page, scope: .key(.layerRotate), enabled: false)

    try context.engine.editor.setSettingBool("page/allowCropInteraction", value: true)
    try context.engine.editor.setSettingBool("page/allowMoveInteraction", value: true)
    try context.engine.editor.setSettingBool("page/allowResizeInteraction", value: true)
    try context.engine.editor.setSettingBool("page/restrictResizeInteractionToFixedAspectRatio", value: false)
    try context.engine.editor.setSettingBool("page/allowRotateInteraction", value: false)
    try context.engine.editor.setSettingBool("page/selectWhenNoBlocksSelected", value: true)
    try context.engine.editor.setSettingBool("doubleClickToCropEnabled", value: false)
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
