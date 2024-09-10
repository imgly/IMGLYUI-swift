import Foundation
@_spi(Internal) import IMGLYCoreUI

enum TextProperty: Labelable, IdentifiableByHash, CaseIterable {
  case inactive, bold, italic

  var description: String {
    switch self {
    case .inactive: return "Inactive"
    case .bold: return "Bold"
    case .italic: return "Italic"
    }
  }

  var imageName: String? {
    switch self {
    case .inactive: return nil
    case .bold: return "bold"
    case .italic: return "italic"
    }
  }
}
