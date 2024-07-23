import Foundation
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public enum Action: Labelable, IdentifiableByHash {
  case undo, redo, previewMode, editMode, export, toTop, up, down, toBottom, duplicate, delete
  case previousPage, nextPage, page(Int), addPage(Int)
  case resetCrop, flipCrop

  @_spi(Internal) public var description: String {
    switch self {
    case .undo: return "Undo"
    case .redo: return "Redo"
    case .previewMode: return "Preview"
    case .editMode: return "Edit"
    case .export: return "Export"
    case .toTop: return "To Top"
    case .up: return "Up"
    case .down: return "Down"
    case .toBottom: return "To Bottom"
    case .duplicate: return "Duplicate"
    case .delete: return "Delete"
    case .previousPage: return "Back"
    case .nextPage: return "Next"
    case let .page(index): return "Page \(index + 1)"
    case .addPage: return "Add Page"
    case .resetCrop: return "Reset Crop"
    case .flipCrop: return "Flip"
    }
  }

  @_spi(Internal) public var imageName: String? {
    switch self {
    case .undo: return "arrow.uturn.backward.circle"
    case .redo: return "arrow.uturn.forward.circle"
    case .previewMode: return "eye"
    case .editMode: return "eye.fill"
    case .export: return "square.and.arrow.up"
    case .toTop: return "square.3.stack.3d.top.fill"
    case .up: return "square.2.stack.3d.top.fill"
    case .down: return "square.2.stack.3d.bottom.fill"
    case .toBottom: return "square.3.stack.3d.bottom.fill"
    case .duplicate: return "plus.square.on.square"
    case .delete: return "trash"
    case .previousPage: return "chevron.backward"
    case .nextPage: return "chevron.forward"
    case .page: return "doc"
    case .addPage: return "plus"
    case .resetCrop: return "arrow.counterclockwise"
    case .flipCrop: return "arrow.left.and.right.righttriangle.left.righttriangle.right"
    }
  }
}
