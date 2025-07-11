import SwiftUI
@_spi(Internal) import IMGLYCoreUI

enum SheetMode: Labelable, IdentifiableByHash {
  case editPage
  case addPage
  case moveUp
  case moveDown

  case delete, duplicate
  case resize

  var localizationValue: String.LocalizationValue {
    switch self {
    case .delete: "ly_img_editor_pages_view_mode_dock_button_delete"
    case .duplicate: "ly_img_editor_pages_view_mode_dock_button_duplicate"
    case .editPage: "ly_img_editor_pages_view_mode_dock_button_edit"
    case .addPage: "ly_img_editor_pages_view_mode_dock_button_add_page"
    case .moveUp: "ly_img_editor_pages_view_mode_dock_button_move_up"
    case .moveDown: "ly_img_editor_pages_view_mode_dock_button_move_down"
    case .resize: "ly_img_editor_pages_view_mode_dock_button_resize"
    }
  }

  var imageName: String? {
    switch self {
    case .delete: "trash"
    case .duplicate: "plus.square.on.square"
    case .editPage: "square.and.pencil"
    case .addPage: "custom.doc.badge.plus"
    case .moveUp: "arrow.up.doc"
    case .moveDown: "arrow.down.doc"
    case .resize: "custom.arrow.down.left.and.arrow.up.right"
    }
  }

  var isSystemImage: Bool {
    guard let imageName else {
      return true
    }
    return !imageName.hasPrefix("custom.")
  }
}
