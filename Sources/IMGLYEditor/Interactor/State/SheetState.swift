import SwiftUI

struct SheetState: BatchMutable {
  var isPresented: Bool
  var model: SheetModel
  var style: SheetStyle

  /// Forwarded `model.mode`.
  var mode: SheetMode {
    get { model.mode }
    set { model.mode = newValue }
  }

  /// Forwarded `model.type`.
  var type: InternalSheetType { model.type }

  /// Combined `model` and `isPresented`.
  var state: SheetModel? { isPresented ? model : nil }

  var isFloating: Bool {
    switch mode {
    case .add: true
    default: style.isFloating
    }
  }

  /// Hide sheet.
  init() {
    self.init(.add, .image, style: .default())
    isPresented = false
  }

  /// Show sheet with `mode`, `type`, and `style`.
  init(_ mode: SheetMode, _ type: InternalSheetType, style: SheetStyle = .default()) {
    isPresented = true
    model = .init(mode, type)
    self.style = style
  }
}
