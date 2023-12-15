import Foundation
@_spi(Internal) import IMGLYCoreUI

enum SheetType: Labelable, IdentifiableByHash {
  case image, text, shape, sticker, group, page
  case selectionColors, font, fontSize, color

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
    }
  }

  var imageName: String? {
    nil
  }
}
