import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct AssetLibrarySheet: View {
  let content: SheetContent?

  @Environment(\.imglyEditorEnvironment) private var editorEnvironment

  @MainActor
  var assetLibrary: some AssetLibrary {
    let categories = AssetLibraryCategory.defaultCategories
    return AnyAssetLibrary(erasing: editorEnvironment.makeAssetLibrary(defaultCategories: categories))
  }

  var body: some View {
    switch content {
    case .image: assetLibrary.imagesTab
    case .text: assetLibrary.textTab
    case .shape: assetLibrary.shapesTab
    case .sticker: assetLibrary.stickersTab
    case .clip: assetLibrary.clipsTab
    case .audio: assetLibrary.audioTab
    default: assetLibrary
    }
  }
}
