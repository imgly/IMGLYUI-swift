import Foundation

@_spi(Internal) public typealias AssetMeta = [AssetMetaKey: String]

@_spi(Internal) public enum AssetMetaKey: String, Sendable {
  case uri
  case thumbUri
  case blockType
  case width
  case height
  case duration
  case fontSize
  case artist
  case title
  case filename
  case kind
  case fillType
  case blurType
  case effectType
  case previewUri
  case looping
  case mimeType
}
