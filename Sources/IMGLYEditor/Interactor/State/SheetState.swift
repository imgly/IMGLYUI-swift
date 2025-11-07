import IMGLYEngine
import SwiftUI

private extension SheetType {
  var objectIdentifier: ObjectIdentifier { .init(Self.self) }
}

struct EquatableSheetType: Equatable {
  let value: SheetType

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.value.objectIdentifier == rhs.value.objectIdentifier
  }
}

struct SheetState: BatchMutable, Equatable {
  var isPresented: Bool
  var mode: SheetMode?
  var content: SheetContent?
  var style: SheetStyle

  private let equatableType: EquatableSheetType?
  var type: SheetType? { equatableType?.value }

  var isFloating: Bool {
    style.isFloating
  }

  var isReplacing: Bool {
    type is SheetTypes.LibraryReplace
  }

  var associatedEditMode: IMGLYEngine.EditMode? {
    (type as? SheetTypeWithEditMode)?.associatedEditMode
  }

  /// Hide sheet.
  init() {
    isPresented = false
    mode = nil
    content = nil
    style = .default()
    equatableType = nil
  }

  /// Show sheet with `mode` and `style`.
  init(_ mode: SheetMode, style: SheetStyle = .default()) {
    isPresented = true
    self.mode = mode
    content = nil
    self.style = style
    equatableType = nil
  }

  /// Show sheet with `type` and optional `content`.
  init(_ type: SheetType, _ content: SheetContent? = nil) {
    isPresented = true
    mode = nil
    self.content = content
    style = type.style
    equatableType = .init(value: type)
  }
}
