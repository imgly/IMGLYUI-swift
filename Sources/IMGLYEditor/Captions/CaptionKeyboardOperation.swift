import Foundation

/// What a keystroke in a caption field should do.
///
/// Captions give Return and Backspace structural meaning, matching web: Return divides a caption, Backspace
/// at the very start joins one back together. Splitting that decision out from the text view keeps it
/// testable — it is a pure function of the field's contents and the caret, with no UIKit, no SwiftUI, and
/// no engine — so the semantics can be pinned down without a keyboard on screen.
enum CaptionKeyOperation: Equatable {
  /// Not a structural key: let the text view apply it normally.
  case passThrough
  /// A structural key with nothing to do here. Consumed, so it doesn't also type a character.
  case ignore
  /// Divide the caption at this UTF-16 offset; the text after it moves to a new caption below.
  case splitAt(utf16Offset: Int)
  /// Append a new, empty caption after this one and edit it.
  case addCaptionAfter
  /// Join this caption into the one above it.
  case mergeWithPrevious
  /// Remove this caption.
  case deleteCaption
}

/// The keyboard semantics of a caption field, as pure decisions.
///
/// Both entry points mirror the UIKit hooks that can observe these keys — `shouldChangeTextIn` for Return
/// and `deleteBackward()` for Backspace — because SwiftUI's `TextField` can observe neither.
enum CaptionKeyboard {
  /// Decides what a pending text replacement means.
  ///
  /// Only a bare Return is structural. Anything else — typing, pasting (even a paste that *contains*
  /// newlines), or an input method confirming a composition — is left alone, so CJK, dictation, and
  /// multi-line pastes behave normally.
  ///
  /// - Parameters:
  ///   - replacement: The text UIKit is about to insert.
  ///   - caretUTF16: Where the replacement starts, as a UTF-16 offset.
  ///   - textLengthUTF16: The field's current length in UTF-16 units.
  ///   - hasMarkedText: Whether an input method is mid-composition.
  static func operation(
    forReplacement replacement: String,
    caretUTF16: Int,
    textLengthUTF16: Int,
    hasMarkedText: Bool,
  ) -> CaptionKeyOperation {
    guard replacement == "\n", !hasMarkedText else { return .passThrough }
    if caretUTF16 >= textLengthUTF16 {
      // Nothing after the caret to divide off, so start the next caption instead.
      return .addCaptionAfter
    }
    guard caretUTF16 > 0 else {
      // Splitting at the very start would leave an empty caption above, which is never what was meant.
      return .ignore
    }
    return .splitAt(utf16Offset: caretUTF16)
  }

  /// Decides what a backspace at the very start of a caption means. Only that press is structural, so the
  /// caller establishes it: a backspace over a selection, or anywhere else in the text, never reaches here
  /// and deletes characters as usual.
  ///
  /// - Parameters:
  ///   - isTextEmpty: Whether the caption has no text at all.
  ///   - hasPreviousCaption: Whether a caption exists above this one to merge into.
  static func backspaceOperation(
    isTextEmpty: Bool,
    hasPreviousCaption: Bool,
  ) -> CaptionKeyOperation {
    if isTextEmpty {
      // Backspacing an empty caption removes it, the same gesture as clearing a blank line.
      return .deleteCaption
    }
    // The first caption has nothing above it, so the key does nothing rather than silently deleting text.
    return hasPreviousCaption ? .mergeWithPrevious : .passThrough
  }
}
