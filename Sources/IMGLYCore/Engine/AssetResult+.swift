import Foundation
import IMGLYEngine

@_spi(Internal) public extension AssetResult {
  internal func meta(_ key: AssetMetaKey) -> String? {
    meta?[key.rawValue]
  }

  var url: URL? {
    guard let string = meta(.uri) else {
      return nil
    }
    return URL(string: string)
  }

  var thumbURL: URL? {
    guard let string = meta(.thumbUri) else {
      return nil
    }
    return URL(string: string)
  }

  var previewURL: URL? {
    guard let string = meta(.previewUri) else {
      return nil
    }
    return URL(string: string)
  }

  var blockType: String? {
    meta(.blockType)
  }

  var blockKind: String? {
    meta(.kind)
  }

  var fillType: String? {
    meta(.fillType)
  }

  var blurType: String? {
    meta(.blurType)
  }

  var effectType: String? {
    meta(.effectType)
  }

  var duration: TimeInterval? {
    guard let string = meta(.duration) else {
      return nil
    }
    return TimeInterval(string)
  }

  var fontSize: CGFloat? {
    guard let string = meta(.fontSize), let value = Int(string) else {
      return nil
    }
    return CGFloat(value)
  }

  var title: String? {
    meta(.title)
  }

  var artist: String? {
    meta(.artist)
  }

  var filename: String? {
    meta(.filename)
  }

  var looping: Bool? {
    guard let string = meta(.looping) else {
      return nil
    }
    return Bool(string)
  }
}
