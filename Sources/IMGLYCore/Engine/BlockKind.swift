import Foundation

@_spi(Internal) public typealias BlockKind = RawRepresentableKey<BlockKindKey>

@_spi(Internal) public enum BlockKindKey: String {
  case image
  case video
  case sticker
  case scene
  case camera
  case stack
  case page
  case audio
  case text
  case shape
  case group
  case voiceover
}
