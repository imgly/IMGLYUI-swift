import Foundation
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public enum Action: Labelable, IdentifiableByHash {
  case toFront, bringForward, sendBackward, toBack, duplicate, delete
  case page(Int), addPage(Int)
  case resetCrop, flipCrop

  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .toFront: "ly_img_editor_sheet_layer_button_bring_to_front"
    case .bringForward: "ly_img_editor_sheet_layer_button_bring_forward"
    case .sendBackward: "ly_img_editor_sheet_layer_button_send_backward"
    case .toBack: "ly_img_editor_sheet_layer_button_send_to_back"
    case .duplicate: "ly_img_editor_sheet_layer_button_duplicate"
    case .delete: "ly_img_editor_sheet_layer_button_delete"
    case let .page(index): "Page \(index + 1)"
    case .addPage: "Add Page"
    case .resetCrop: "ly_img_editor_sheet_crop_button_reset"
    case .flipCrop: "ly_img_editor_sheet_crop_button_flip"
    }
  }

  @_spi(Internal) public var imageName: String? {
    switch self {
    case .toFront: "square.3.stack.3d.top.fill"
    case .bringForward: "square.2.stack.3d.top.fill"
    case .sendBackward: "square.2.stack.3d.bottom.fill"
    case .toBack: "square.3.stack.3d.bottom.fill"
    case .duplicate: "plus.square.on.square"
    case .delete: "trash"
    case .page: "doc"
    case .addPage: "plus"
    case .resetCrop: "arrow.counterclockwise"
    case .flipCrop: "arrow.left.and.right.righttriangle.left.righttriangle.right"
    }
  }
}
