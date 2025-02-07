import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct AssetLibrarySheet: View {
  let content: SheetContent?

  @Environment(\.imglyAssetLibrary) private var anyAssetLibrary

  @MainActor
  var assetLibrary: some AssetLibrary {
    anyAssetLibrary ?? AnyAssetLibrary(erasing: DefaultAssetLibrary())
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
