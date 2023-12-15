import SwiftUI

@MainActor
struct AssetLibraryKey: EnvironmentKey {
  static let defaultValue: AnyAssetLibrary? = nil
}

@_spi(Internal) public extension EnvironmentValues {
  var imglyAssetLibrary: AnyAssetLibrary? {
    get { self[AssetLibraryKey.self] }
    set { self[AssetLibraryKey.self] = newValue }
  }
}

@_spi(Internal) public struct AnyAssetLibrary: AssetLibrary, Sendable {
  @_spi(Internal) public var videosTab: some View { AnyView(erasing: assetLibrary().videosTab) }
  @_spi(Internal) public var audioTab: some View { AnyView(erasing: assetLibrary().audioTab) }
  @_spi(Internal) public var imagesTab: some View { AnyView(erasing: assetLibrary().imagesTab) }
  @_spi(Internal) public var stickersTab: some View { AnyView(erasing: assetLibrary().stickersTab) }

  private let assetLibrary: () -> any AssetLibrary

  @_spi(Internal) public init(erasing assetLibrary: some AssetLibrary) {
    self.assetLibrary = { assetLibrary }
  }

  @_spi(Internal) public var body: some View {
    AnyView(erasing: assetLibrary())
  }
}
