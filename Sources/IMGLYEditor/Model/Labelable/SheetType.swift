import Foundation
@_spi(Internal) import IMGLYCoreUI

enum SheetType: Labelable, IdentifiableByHash {
  case image, text, shape, sticker, group, page, video, audio
  case selectionColors, font, fontSize, color
  case reorder
  case backgroundTrackLibrary
  case overlayLibrary
  case stickerShapesLibrary

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
    case .reorder: return "Reorder"
    case .backgroundTrackLibrary: return "Background Track"
    case .overlayLibrary: return "Overlay Library"
    case .stickerShapesLibrary: return "Stickers"
    }
  }

  var imageName: String? {
    nil
  }
}
