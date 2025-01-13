import Foundation
@_spi(Internal) import IMGLYCoreUI

enum InternalSheetType: Labelable, IdentifiableByHash {
  case image, text, shape, sticker, group, page, video, audio, voiceover
  case selectionColors, font, fontSize, color
  case reorder
  case asset, clip
  case pageOverview

  var description: String {
    switch self {
    case .image: "Image"
    case .text: "Text"
    case .shape: "Shape"
    case .sticker: "Sticker"
    case .group: "Group"
    case .selectionColors: "Template Colors"
    case .font: "Font"
    case .fontSize: "Size"
    case .color: "Color"
    case .page: "Page"
    case .video: "Video"
    case .audio: "Audio"
    case .voiceover: "Voiceover"
    case .reorder: "Reorder"
    case .asset: "Asset"
    case .clip: "Clip"
    case .pageOverview: "Page Overview"
    }
  }

  var imageName: String? {
    nil
  }
}
