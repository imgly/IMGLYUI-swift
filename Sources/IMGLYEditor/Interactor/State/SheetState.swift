import SwiftUI

struct SheetState: BatchMutable {
  var isPresented: Bool
  var model: SheetModel
  var detent: PresentationDetent = .adaptiveMedium
  var detents: Set<PresentationDetent> = [.adaptiveMedium, .adaptiveLarge]
  var largestUndimmedDetent: PresentationDetent? {
    if detents.contains(.medium) {
      .medium
    } else if detents.contains(.adaptiveMedium) {
      .adaptiveMedium
    } else if detents.contains(.adaptiveSmall) {
      .adaptiveSmall
    } else if detents.contains(.adaptiveTiny) {
      .adaptiveTiny
    } else {
      nil
    }
  }

  /// Forwarded `model.mode`.
  var mode: SheetMode {
    get { model.mode }
    set { model.mode = newValue }
  }

  /// Forwarded `model.type`.
  var type: SheetType { model.type }

  /// Combined `model` and `isPresented`.
  var state: SheetModel? { isPresented ? model : nil }

  /// Hide sheet.
  init() {
    isPresented = false
    model = .init(.add, .image)
  }

  /// Show sheet with `mode` and `type`.
  init(_ mode: SheetMode, _ type: SheetType) {
    isPresented = true
    model = .init(mode, type)
  }
}
