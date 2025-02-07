import SwiftUI
@_spi(Internal) import IMGLYCoreUI

enum SheetMode: Labelable, IdentifiableByHash {
  case editPage
  case addPage
  case moveUp
  case moveDown

  case selectionColors
  case font(_ id: Interactor.BlockID?, _ fontFamilies: [String]?)
  case fontSize(_ id: Interactor.BlockID?)
  case color(_ id: Interactor.BlockID?, _ colorPalette: [NamedColor]?)
  case delete, duplicate

  var pinnedBlockID: Interactor.BlockID? {
    switch self {
    case let .font(id, _): id
    case let .fontSize(id): id
    case let .color(id, _): id
    default: nil
    }
  }

  var fontFamilies: [String]? {
    switch self {
    case let .font(_, families): families
    default: nil
    }
  }

  var colorPalette: [NamedColor]? {
    switch self {
    case let .color(_, palette): palette
    default: nil
    }
  }

  var description: String {
    switch self {
    case .selectionColors: "Colors"
    case .font: "Font"
    case .fontSize: "Size"
    case .color: "Color"
    case .delete: "Delete"
    case .duplicate: "Duplicate"
    case .editPage: "Edit"
    case .addPage: "Add Page"
    case .moveUp: "Move Up"
    case .moveDown: "Move Down"
    }
  }

  var imageName: String? {
    switch self {
    case .selectionColors, .font, .fontSize, .color: nil
    case .delete: "trash"
    case .duplicate: "plus.square.on.square"
    case .editPage: "square.and.pencil"
    case .addPage: "custom.doc.badge.plus"
    case .moveUp: "arrow.up.doc"
    case .moveDown: "arrow.down.doc"
    }
  }

  var isSystemImage: Bool {
    guard let imageName else {
      return true
    }
    return !imageName.hasPrefix("custom.")
  }

  @MainActor
  func localizedStringKey(_: Interactor.BlockID?, _: Interactor) -> LocalizedStringKey {
    localizedStringKey
  }

  @MainActor @ViewBuilder func label(_: Interactor.BlockID?, _: Interactor) -> some View {
    switch self {
    case .selectionColors:
      Label {
        Text(localizedStringKey)
      } icon: {
        SelectionColorsIcon()
      }
    case .font:
      Label {
        Text(localizedStringKey)
      } icon: {
        FontIcon()
      }
    case .fontSize:
      Label {
        Text(localizedStringKey)
      } icon: {
        FontSizeIcon()
      }
    case .color:
      Label {
        Text(localizedStringKey)
      } icon: {
        FillColorIcon()
      }
    default: label
    }
  }
}
