import Foundation
@_spi(Internal) import IMGLYCoreUI

enum SheetType: Labelable, IdentifiableByHash {
  case image, text, shape, sticker, group, page, video, audio, voiceover
  case selectionColors, font, fontSize, color
  case reorder
  case asset, elements, clip, overlay, stickerOrShape
  case pageOverview

  var description: String {
    switch self {
    case .image: return "Image"
    case .text: return "Text"
    case .shape: return "Shape"
    case .sticker: return "Sticker"
    case .group: return "Group"
    case .selectionColors: return "Template Colors"
    case .font: return "Font"
    case .fontSize: return "Size"
    case .color: return "Color"
    case .page: return "Page"
    case .video: return "Video"
    case .audio: return "Audio"
    case .voiceover: return "Voiceover"
    case .reorder: return "Reorder"
    case .asset: return "Asset"
    case .elements: return "Elements"
    case .clip: return "Clip"
    case .overlay: return "Overlay"
    case .stickerOrShape: return "Sticker"
    case .pageOverview: return "Page Overview"
    }
  }

  var imageName: String? {
    nil
  }
}
