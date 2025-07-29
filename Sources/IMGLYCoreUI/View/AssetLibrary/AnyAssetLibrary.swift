import SwiftUI

@_spi(Internal) public extension EnvironmentValues {
  @Entry var imglyAssetLibrary: AnyAssetLibrary?
}

@MainActor
@_spi(Internal) public struct AnyAssetLibrary: AssetLibrary {
  @_spi(Internal) public var elementsTab: some View { AnyView(erasing: assetLibrary().elementsTab) }
  @_spi(Internal) public var videosTab: some View { AnyView(erasing: assetLibrary().videosTab) }
  @_spi(Internal) public var audioTab: some View { AnyView(erasing: assetLibrary().audioTab) }
  @_spi(Internal) public var imagesTab: some View { AnyView(erasing: assetLibrary().imagesTab) }
  @_spi(Internal) public var textTab: some View { AnyView(erasing: assetLibrary().textTab) }
  @_spi(Internal) public var shapesTab: some View { AnyView(erasing: assetLibrary().shapesTab) }
  @_spi(Internal) public var stickersTab: some View { AnyView(erasing: assetLibrary().stickersTab) }

  @_spi(Internal) public var clipsTab: some View { AnyView(erasing: assetLibrary().clipsTab) }
  @_spi(Internal) public var overlaysTab: some View { AnyView(erasing: assetLibrary().overlaysTab) }
  @_spi(Internal) public var stickersAndShapesTab: some View { AnyView(erasing: assetLibrary().stickersAndShapesTab) }

  private let assetLibrary: () -> any AssetLibrary

  @_spi(Internal) public init(erasing assetLibrary: some AssetLibrary) {
    self.assetLibrary = { assetLibrary }
  }

  @_spi(Internal) public var body: some View {
    AnyView(erasing: assetLibrary())
  }
}
