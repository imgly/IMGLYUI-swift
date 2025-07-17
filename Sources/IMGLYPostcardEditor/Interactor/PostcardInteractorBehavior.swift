@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYEditor
import SwiftUI

final class PostcardInteractorBehavior: InteractorBehavior {
  var historyResetOnPageChange: HistoryResetBehavior { .always }
  var deselectOnPageChange: Bool { true }
  var previewMode: PreviewMode { .fixed }

  func loadScene(_ context: InteractorContext, with insets: EdgeInsets?) async throws {
    try await DefaultInteractorBehavior.default.loadScene(context, with: insets)
    context.interactor.selectionColors = try context.engine.selectionColors(
      forPage: 0,
      includeDisabled: true,
      setDisabled: true,
      ignoreScope: true
    )
    try context.engine.editor.setGlobalScope(key: ScopeKey.editorAdd.rawValue, value: .defer)
  }

  func rootBottomBarItems(_ context: InteractorContext) throws -> [RootBottomBarItem] {
    if context.interactor.page != 1 {
      return [.fab, .selectionColors]
    } else {
      guard let id = context.engine.block.find(byName: "Greeting").first else {
        throw Error(errorDescription: "No greeting found.")
      }
      return [
        .font(id, fontFamilies: [
          "Caveat", "Amatic SC", "Courier Prime", "Archivo", "Roboto", "Parisienne",
        ]),
        .fontSize(id),
        .color(id, colorPalette: [
          .init("Governor Bay", .imgly.hex("#263BAA")!),
          .init("Resolution Blue", .imgly.hex("#002094")!),
          .init("Stratos", .imgly.hex("#001346")!),
          .init("Blue Charcoal", .imgly.hex("#000514")!),
          .init("Black", .imgly.hex("#000000")!),
          .init("Dove Gray", .imgly.hex("#696969")!),
          .init("Dusty Gray", .imgly.hex("#999999")!),
        ]),
      ]
    }
  }

  func enablePreviewMode(_ context: InteractorContext, _ insets: EdgeInsets?) async throws {
    try disableCameraClamping(context)
    try showAllPages(context)
    try await context.engine.zoomToScene(insets)
    try context.engine.block.deselectAll()
  }

  func updateState(_: InteractorContext) throws {}
}

extension InteractorBehavior where Self == PostcardInteractorBehavior {
  static var postcard: Self { Self() }
}
