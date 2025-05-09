import Foundation
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public enum Action: Labelable, IdentifiableByHash {
  case undo, redo, previewMode, editMode, export, toTop, up, down, toBottom, duplicate, delete
  case previousPage, nextPage, page(Int), addPage(Int)
  case resetCrop, flipCrop

  @_spi(Internal) public var description: String {
    switch self {
    case .undo: "Undo"
    case .redo: "Redo"
    case .previewMode: "Preview"
    case .editMode: "Edit"
    case .export: "Export"
    case .toTop: "To Top"
    case .up: "Up"
    case .down: "Down"
    case .toBottom: "To Bottom"
    case .duplicate: "Duplicate"
    case .delete: "Delete"
    case .previousPage: "Back"
    case .nextPage: "Next"
    case let .page(index): "Page \(index + 1)"
    case .addPage: "Add Page"
    case .resetCrop: "Reset Crop"
    case .flipCrop: "Flip"
    }
  }

  @_spi(Internal) public var imageName: String? {
    switch self {
    case .undo: "arrow.uturn.backward.circle"
    case .redo: "arrow.uturn.forward.circle"
    case .previewMode: "eye"
    case .editMode: "eye.fill"
    case .export: "square.and.arrow.up"
    case .toTop: "square.3.stack.3d.top.fill"
    case .up: "square.2.stack.3d.top.fill"
    case .down: "square.2.stack.3d.bottom.fill"
    case .toBottom: "square.3.stack.3d.bottom.fill"
    case .duplicate: "plus.square.on.square"
    case .delete: "trash"
    case .previousPage: "chevron.backward"
    case .nextPage: "chevron.forward"
    case .page: "doc"
    case .addPage: "plus"
    case .resetCrop: "arrow.counterclockwise"
    case .flipCrop: "arrow.left.and.right.righttriangle.left.righttriangle.right"
    }
  }
}
