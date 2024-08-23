import Foundation
@_spi(Internal) import IMGLYCoreUI

enum TextProperty: Labelable, IdentifiableByHash, CaseIterable {
  case inactive, bold, italic

  var description: String {
    switch self {
    case .inactive: "Inactive"
    case .bold: "Bold"
    case .italic: "Italic"
    }
  }

  var imageName: String? {
    switch self {
    case .inactive: nil
    case .bold: "bold"
    case .italic: "italic"
    }
  }
}
