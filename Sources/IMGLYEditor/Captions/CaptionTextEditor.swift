import IMGLYEngine
import SwiftUI
import UIKit

/// A caret position requested for a caption that is about to take focus — used to open the tail of a split
/// at the cut rather than at the end of the text.
struct CaptionCaret: Equatable {
  let caption: DesignBlockID
  let offset: Int
}

// MARK: - Backspace-aware text view

/// A `UITextView` that reports a backspace at the very start of the text — the one key gesture no SwiftUI
/// text view can observe. Unhandled presses fall through to the native delete.
final class CaptionTextView: UITextView {
  /// Returns whether the key was consumed.
  var onBackspaceAtStart: (@MainActor (_ isEmpty: Bool) -> Bool)?

  override func deleteBackward() {
    // This gate is the contract: `CaptionKeyboard.backspaceOperation` assumes a collapsed caret at offset 0
    // rather than re-checking it.
    if let selection = selectedTextRange,
       selection.isEmpty,
       offset(from: beginningOfDocument, to: selection.start) == 0,
       let onBackspaceAtStart,
       onBackspaceAtStart(text.isEmpty) {
      return
    }
    super.deleteBackward()
  }
}

// MARK: - Caption text editor

/// The editing field of a caption row, backed by `UITextView` because SwiftUI's `TextField` can observe
/// neither the delete key nor the caret that caption editing needs. What each key means is decided by
/// ``CaptionKeyboard`` — this type only routes the result.
///
/// The field owns its text while editing: `text` seeds it, and later edits flow out through `onTextChange`
/// rather than being written back in. `textViewDidEndEditing` is *not* delivered when SwiftUI tears a
/// representable down, so it can never be the commit trigger — the row commits from the live text instead.
struct CaptionTextEditor: UIViewRepresentable {
  /// Seed text. Re-applied whenever ``externalRevision`` changes, including while the field holds the
  /// keyboard — that is how a merge's joined text and a split's shortened head reach the field.
  let text: String
  /// Bumped by the row each time it re-reads `text` from the engine. Assigning `.text` does not call the
  /// delegate back, so this can't loop: only genuine external rewrites land.
  let externalRevision: Int
  /// Where to leave the caret after an external rewrite. `nil` keeps it at the end.
  let caretAfterExternalChange: Int?
  /// Whether this row should hold the keyboard.
  let isFocused: Bool
  /// Whether *some* row is being edited. A row that has lost focus while another is taking it must not
  /// resign: handing over by resigning first closes the keyboard for the gap in between, which is what
  /// makes add-after and row-to-row moves flicker. Taking first responder moves it implicitly.
  let isEditingActive: Bool
  /// Whether a caption exists above this one, which decides if backspace-at-start can merge.
  let hasPreviousCaption: Bool
  let accessibilityLabel: String
  /// Live text on every keystroke.
  let onTextChange: @MainActor (String) -> Void
  /// The field resigned on its own (interactive keyboard dismiss), so the row can leave editing.
  let onEditingEnded: @MainActor () -> Void
  /// Hands the row its backing text view, so the sheet's action bar can read the caret and live text.
  let onTextViewReady: @MainActor (CaptionTextView) -> Void
  /// A requested caret was applied, so it isn't reused by a later rewrite.
  let onCaretApplied: @MainActor () -> Void
  /// Runs a structural operation. Returns whether it happened, so the key can be consumed.
  let onOperation: @MainActor (CaptionKeyOperation, _ liveText: String) -> Bool

  private static let maxVisibleLines = 3

  func makeUIView(context: Context) -> CaptionTextView {
    let view = CaptionTextView()
    view.delegate = context.coordinator
    view.backgroundColor = .clear
    view.textColor = .label
    // Match the SwiftUI body/medium the rest of the row uses, so nothing reflows.
    view.font = UIFontMetrics(forTextStyle: .body)
      .scaledFont(for: .systemFont(ofSize: 17, weight: .medium))
    view.adjustsFontForContentSizeCategory = true
    view.isScrollEnabled = false
    view.alwaysBounceVertical = false
    view.textContainerInset = .zero
    view.textContainer.lineFragmentPadding = 0
    view.accessibilityLabel = accessibilityLabel
    view.text = text
    view.onBackspaceAtStart = { [weak coordinator = context.coordinator, weak view] isEmpty in
      guard let coordinator, let view else { return false }
      return coordinator.handleBackspaceAtStart(view, isEmpty: isEmpty)
    }
    onTextViewReady(view)
    return view
  }

  func updateUIView(_ view: CaptionTextView, context: Context) {
    context.coordinator.parent = self
    view.accessibilityLabel = accessibilityLabel
    context.coordinator.applyExternalTextIfNeeded(view)
    // Independent of the text: an operation can leave the text identical (merging into an empty caption
    // joins to the same string) and the caret still has to move.
    context.coordinator.placeRequestedCaret(view)
    context.coordinator.syncFirstResponder(view, shouldFocus: isFocused, isEditingActive: isEditingActive)
  }

  func sizeThatFits(_ proposal: ProposedViewSize, uiView: CaptionTextView, context _: Context) -> CGSize? {
    guard let width = proposal.width, width > 0, width < .greatestFiniteMagnitude else { return nil }
    let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    let cap = Self.maxHeight(of: uiView)
    // Scroll only past the cap — an always-scrollable field would swallow the list's drags. Deferred
    // because the view can't be mutated during layout.
    let shouldScroll = fitted.height > cap + 0.5
    if uiView.isScrollEnabled != shouldScroll {
      DispatchQueue.main.async {
        MainActor.assumeIsolated {
          uiView.isScrollEnabled = shouldScroll
          uiView.scrollRangeToVisible(uiView.selectedRange)
        }
      }
    }
    return CGSize(width: width, height: min(fitted.height, cap))
  }

  private static func maxHeight(of view: UITextView) -> CGFloat {
    let lineHeight = view.font?.lineHeight ?? UIFont.preferredFont(forTextStyle: .body).lineHeight
    return ceil(lineHeight * CGFloat(maxVisibleLines))
      + view.textContainerInset.top + view.textContainerInset.bottom
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  @MainActor
  final class Coordinator: NSObject, UITextViewDelegate {
    var parent: CaptionTextEditor
    /// Set while a structural operation is being applied, so an auto-repeating key can't fire it twice
    /// before the resulting update lands. Cleared on the next run-loop turn rather than when the field is
    /// re-seeded: an operation can leave the text untouched — merging into an empty caption joins to the
    /// same string — and a flag that waited for a rewrite would latch, silently killing Return and
    /// Backspace on that row for the rest of the editing session.
    private var isOperationInFlight = false
    /// The last external revision written into the field, so each one is applied exactly once.
    private var appliedRevision = 0

    init(_ parent: CaptionTextEditor) {
      self.parent = parent
    }

    /// Writes an engine-side rewrite into the field. This has to work *while focused* — a merge folds the
    /// next caption's text into the one being edited, and a split shortens it — which is why it keys off an
    /// explicit revision rather than comparing strings: comparing would either fight the user's typing or
    /// miss a rewrite that happens to match.
    func applyExternalTextIfNeeded(_ view: CaptionTextView) {
      guard parent.externalRevision != appliedRevision else { return }
      appliedRevision = parent.externalRevision
      if view.text != parent.text {
        view.text = parent.text
      }
      // Assigning `.text` parks the caret at the end, which is the right default; the caller places any
      // requested caret afterwards.
    }

    /// Marks an operation as running and releases the guard once the current turn has drained, which is
    /// all that key-repeat can span.
    private func beginOperation() {
      isOperationInFlight = true
      DispatchQueue.main.async { [weak self] in
        MainActor.assumeIsolated { self?.isOperationInFlight = false }
      }
    }

    /// Applies a requested caret, if there is one. Deliberately does nothing otherwise: the caret is
    /// already where it belongs by then — at the end of freshly assigned text, or where an earlier pass
    /// put it — and forcing it to the end here would undo that. Consumes the request, since a caret left
    /// standing would be re-applied by the next rewrite of this caption.
    func placeRequestedCaret(_ view: CaptionTextView) {
      guard let requested = parent.caretAfterExternalChange else { return }
      let end = (view.text as NSString).length
      view.selectedRange = NSRange(location: min(requested, end), length: 0)
      if view.isFirstResponder {
        view.scrollRangeToVisible(view.selectedRange)
      }
      // Deferred: this reports back into SwiftUI state, and the caret is placed from `updateUIView` and
      // from `textViewDidBeginEditing`, both of which can run inside a view update.
      let onCaretApplied = parent.onCaretApplied
      DispatchQueue.main.async {
        MainActor.assumeIsolated { onCaretApplied() }
      }
    }

    // MARK: Focus

    /// Mirrors the row's focus onto the responder.
    ///
    /// Resigning only happens when editing has ended altogether. While another row is taking over, this
    /// one holds on and lets that row's `becomeFirstResponder()` move it — resigning first would leave a
    /// gap with no responder, and the keyboard would close and reopen.
    func syncFirstResponder(_ view: CaptionTextView, shouldFocus: Bool, isEditingActive: Bool) {
      if shouldFocus {
        guard !view.isFirstResponder else { return }
        // Take first responder *now* when the view can. Deferring it leaves a turn in which the outgoing
        // row — which may be being deleted in this very update — is still the first responder; tearing it
        // down then drops the keyboard, and it reopens a frame later. Only a view that isn't in a window
        // yet has to wait and retry.
        if view.window != nil, view.becomeFirstResponder() {
          return
        }
        attemptFocus(view, attempts: 10)
      } else if !isEditingActive, view.isFirstResponder {
        view.resignFirstResponder()
      }
    }

    /// Takes first responder once the view is in a window, retrying across run-loop turns:
    /// `becomeFirstResponder()` fails silently off-window, and a freshly created row is not attached on
    /// the first turn. Deferred so it can't re-enter the SwiftUI update.
    private func attemptFocus(_ view: CaptionTextView, attempts: Int) {
      DispatchQueue.main.async { [weak self, weak view] in
        MainActor.assumeIsolated {
          guard let self, let view, !view.isFirstResponder else { return }
          if view.window != nil, view.becomeFirstResponder() {
            return
          }
          guard attempts > 1 else { return }
          self.attemptFocus(view, attempts: attempts - 1)
        }
      }
    }

    // MARK: UITextViewDelegate

    func textViewDidBeginEditing(_ textView: UITextView) {
      // A caret requested but not yet applied lands here — the position after a programmatic focus isn't
      // contractual. If it was already applied above, this leaves it untouched.
      guard let view = textView as? CaptionTextView else { return }
      placeRequestedCaret(view)
    }

    func textViewDidEndEditing(_: UITextView) {
      parent.onEditingEnded()
    }

    func textViewDidChange(_ textView: UITextView) {
      parent.onTextChange(textView.text)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
      let operation = CaptionKeyboard.operation(
        forReplacement: text,
        caretUTF16: range.location,
        textLengthUTF16: (textView.text as NSString).length,
        hasMarkedText: textView.markedTextRange != nil,
      )
      guard operation != .passThrough else { return true }
      guard !isOperationInFlight else { return false }
      if operation != .ignore, parent.onOperation(operation, textView.text) {
        beginOperation()
      }
      return false
    }

    // MARK: Backspace routing

    /// Returns whether the key was consumed.
    func handleBackspaceAtStart(_ view: CaptionTextView, isEmpty: Bool) -> Bool {
      let operation = CaptionKeyboard.backspaceOperation(
        isTextEmpty: isEmpty,
        hasPreviousCaption: parent.hasPreviousCaption,
      )
      guard operation != .passThrough else { return false }
      guard !isOperationInFlight else { return true }
      if parent.onOperation(operation, view.text) {
        beginOperation()
      }
      return true
    }
  }
}
