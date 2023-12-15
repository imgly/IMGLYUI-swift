import Foundation

@_spi(Internal) public enum AssetItem {
  case asset(AssetLoader.Asset)
  case placeholder
}
