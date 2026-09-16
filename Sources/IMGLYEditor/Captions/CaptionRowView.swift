import IMGLYEngine
import SwiftUI
import UIKit
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

/// A caption row with two states: idle (plain text) and editing (a focused text field with the action bar
/// above the keyboard). Tapping a row edits it; swiping it exposes the same actions without editing.
/// The text field's own text is local `@State`, loaded from the engine and committed on focus loss; every
/// engine read is `isValid`-guarded via the domain layer.
struct CaptionRowView: View {
  let caption: DesignBlockID
  /// The caption before this one, if any — the merge target. `nil` for the first row.
  let previousCaption: DesignBlockID?
  let captionsInteractor: CaptionsInteractor
  @Binding var selectedCaption: DesignBlockID?
  @Binding var focusedCaption: DesignBlockID?
  /// A changed value re-renders the row so the field reloads its engine-backed text.
  let reloadToken: Int
  let isMutating: Bool
  let onChange: () -> Void
  let onAddAfter: (DesignBlockID) async -> Void
  /// Splits the caption at a UTF-16 caret offset and moves editing to the tail.
  let onSplitAtCaret: (DesignBlockID, Int) -> Void
  /// Moves editing to another caption with the caret at an offset.
  let onEditCaption: (DesignBlockID, Int) -> Void
  /// Clears the sheet's caret request once this row has applied it.
  let onCaretApplied: () -> Void
  /// A caret requested for this caption as it takes focus (the tail of a split opens at the cut).
  let pendingCaret: CaptionCaret?
  /// Every row's text view, so focus can be moved to a caption before its neighbour is torn down.
  let textViewRegistry: CaptionTextViewRegistry

  /// The field's text — loaded from the engine and committed on blur.
  @State private var text = ""
  /// True only while the user is actively editing *this* row, so a stale row can't write its text back on
  /// another row's focus change or an off-screen rebuild.
  @State private var isEditing = false
  /// Whether the initial engine load has run; guards `commit()` from persisting the empty pre-load value.
  @State private var didLoad = false
  /// The engine text this row last read or wrote — its picture of the stored value. When the engine
  /// diverges from it, the caption was changed by something other than this field.
  @State private var loadedText = ""
  /// Bumped on every engine re-read, so the editor knows to write the new value into a field that may be
  /// holding the keyboard (a merge joins text into it; a split shortens it).
  @State private var externalRevision = 0
  /// Where the caret belongs after the next external rewrite — the join position after a merge.
  @State private var caretAfterExternalChange: Int?

  private var isSelected: Bool {
    selectedCaption == caption
  }

  /// The caret the sheet asked for, when it is meant for this caption.
  ///
  /// Withheld until the row has read its text. A split hands the tail's caret over before the new row
  /// has loaded, and the editor consumes a caret request the first time it sees one — so passing it
  /// early would spend it against the still-empty field, and the real text would then arrive and park
  /// the caret at the end, which is the opposite of what a split asks for.
  private var caretFromPending: Int? {
    guard didLoad else { return nil }
    return pendingCaret.flatMap { $0.caption == caption ? $0.offset : nil }
  }

  private var isFocused: Bool {
    focusedCaption == caption
  }

  /// The first row has no previous caption to merge into.
  private var isFirst: Bool {
    previousCaption == nil
  }

  private var placeholder: String {
    String(localized: .imgly.localized("ly_img_editor_sheet_captions_row_placeholder"))
  }

  var body: some View {
    card
      // The keyboard bar only exists while editing, so swiping offers the same operations straight from
      // the idle list. Full swipe is off so a hurried gesture can't destroy a caption outright.
      //
      // Withdrawn entirely while *any* row is being edited: these actions mutate blocks other rows may be
      // holding uncommitted text for (a merge can even land on the edited row itself), and only the row
      // that owns a field can commit it — so the edited row's text would be silently overwritten. While
      // editing, the keyboard bar is the way in, and it acts on the row that owns the text.
      .swipeActions(edge: .trailing, allowsFullSwipe: false) {
        if focusedCaption == nil {
          swipeActions
        }
      }
      .task(id: caption) {
        load()
        // A caption created and focused in the same update arrives already focused, so the focus-change
        // handler below never fires for it. Without this the row never counts as editing, and the paths
        // that commit on blur — the only ones that save typing — would skip it entirely.
        isEditing = isFocused
      }
      .onChange(of: reloadToken) { _ in
        // One rule covers both kinds of change. An idle row always mirrors the engine. A row being edited
        // keeps its in-flight text — but only while the engine still holds the value this row last saw;
        // once they diverge something else rewrote the caption (a merge folded text in, a split shortened
        // it, an undo landed) and the field has to take the engine's word for it.
        if !isFocused || captionsInteractor.text(of: caption) != loadedText {
          load()
        }
      }
      .onChange(of: focusedCaption) { newFocus in
        if newFocus == caption {
          // Re-read as editing starts: a merge folds the next caption's text into this one and focuses it
          // in the same pass, so the field must show the joined result, not its pre-merge text.
          load()
          isEditing = true
        } else if isEditing {
          // Commit only the row the user was editing when it loses focus.
          isEditing = false
          commit()
        }
      }
      .onDisappear {
        // Save an in-progress edit if the row goes away mid-edit.
        if isEditing {
          isEditing = false
          commit()
        }
      }
  }

  /// The tappable text card. The field is always present so moving focus between rows never tears one
  /// down (which would drop the keyboard).
  private var card: some View {
    cardChrome(field)
      .accessibilityActions { accessibilityRowActions }
  }

  /// The shared card surface: padding, rounded fill, the selection ring, and — while the row isn't focused
  /// — a tap-catcher over the whole card (including the padding) so a tap anywhere selects or edits it.
  private func cardChrome(_ content: some View) -> some View {
    content
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        Color(uiColor: .secondarySystemGroupedBackground),
        in: RoundedRectangle(cornerRadius: 16, style: .continuous),
      )
      .overlay {
        if isSelected {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color.accentColor, lineWidth: 2)
            .allowsHitTesting(false)
        }
      }
      .overlay {
        // The field only takes taps while focused (to place the caret); otherwise this catches them so the
        // whole card — not just the text's own frame — responds.
        if !isFocused {
          Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: handleTap)
        }
      }
  }

  /// The editing field. Return and Backspace carry structural meaning here rather than inserting a line
  /// break or deleting across captions — see ``CaptionKeyboard`` — so the field is a `UITextView`, which
  /// is the only way to observe those keys.
  private var field: some View {
    ZStack(alignment: .leading) {
      // The editor draws no placeholder of its own, so show one behind an empty field.
      if text.isEmpty {
        Text(placeholder)
          .font(.body.weight(.medium))
          .foregroundStyle(.secondary)
          .allowsHitTesting(false)
      }
      CaptionTextEditor(
        text: text,
        externalRevision: externalRevision,
        caretAfterExternalChange: caretAfterExternalChange ?? caretFromPending,
        isFocused: isFocused,
        isEditingActive: focusedCaption != nil,
        hasPreviousCaption: previousCaption != nil,
        // Only a name here — the text view exposes its own text as the accessibility value, so repeating
        // it as the label makes VoiceOver announce every caption twice.
        accessibilityLabel: placeholder,
        onTextChange: { text = $0 },
        onEditingEnded: {
          // The keyboard was dismissed by the user rather than by us, so leave editing.
          if isFocused {
            focusedCaption = nil
          }
        },
        onTextViewReady: { textViewRegistry.register($0, for: caption) },
        onCaretApplied: {
          caretAfterExternalChange = nil
          onCaretApplied()
        },
        onOperation: handleKeyOperation,
      )
      .allowsHitTesting(isFocused)
    }
  }

  /// Runs a structural keystroke (Return / Backspace-at-start) against this caption, committing the field's
  /// live text first so the operation divides or joins what is on screen. Returns whether it ran, so the
  /// editor knows to consume the key.
  private func handleKeyOperation(_ operation: CaptionKeyOperation, liveText: String) -> Bool {
    guard !isMutating else { return false }
    text = liveText
    commit()
    switch operation {
    case let .splitAt(offset):
      onSplitAtCaret(caption, offset)
    case .addCaptionAfter:
      Task { await onAddAfter(caption) }
    case .mergeWithPrevious:
      mergeWithPrevious()
    case .deleteCaption:
      // Backspacing an empty caption removes it and carries on at the end of the one above — the same
      // gesture as clearing a blank line in any editor.
      // Move first responder to the caption above *before* anything is deleted. Going through state alone
      // isn't enough: the state change and this row's removal land in the same SwiftUI update, and if the
      // removal happens first the keyboard is torn down with it. Taking the responder directly here means
      // the keyboard is already somewhere safe by the time this row disappears.
      if let previous = previousCaption {
        textViewRegistry.focus(previous)
        onEditCaption(previous, captionsInteractor.text(of: previous).utf16.count)
      }
      delete()
    case .passThrough, .ignore:
      return false
    }
    return true
  }

  /// The row's quick actions. Declared outermost-first, so they read Merge · Add · Delete with the
  /// destructive one at the swiped edge. Icon-only: three titles side by side truncate to the point of
  /// being unreadable, and the icons match the keyboard bar's. Split is deliberately absent — it cuts at
  /// the caret, which only exists while the row is being edited, so it stays in the keyboard bar.
  /// Acts straight from the swipe rather than opening a menu from it. A swipe-action button runs its
  /// action on tap and cannot host a `Menu`, and the tap closes the swipe, so routing through one would
  /// mean the row sliding shut before its own actions appeared.
  ///
  /// The icons are the ones the keyboard bar's menu names, so the two surfaces teach one symbol each.
  @ViewBuilder private var swipeActions: some View {
    Button(role: .destructive, action: delete) {
      Image.imgly.delete
    }
    .accessibilityLabel(Text(.imgly.localized("ly_img_editor_sheet_captions_row_delete")))
    // Accent on add: of the three it is the one reached for most, and the only one that is neither
    // destructive nor a correction.
    Button {
      Task { await onAddAfter(caption) }
    } label: {
      Image(systemName: "plus")
    }
    .tint(.accentColor)
    .accessibilityLabel(Text(.imgly.localized("ly_img_editor_sheet_captions_row_add_after")))
    if !isFirst {
      Button(action: mergeWithPrevious) {
        Image(systemName: "arrow.triangle.merge")
      }
      .tint(.gray)
      .accessibilityLabel(Text(.imgly.localized("ly_img_editor_sheet_captions_row_merge")))
    }
  }

  /// Row actions exposed to VoiceOver, which can't reach the keyboard bar the touch flow relies on.
  @ViewBuilder private var accessibilityRowActions: some View {
    Button(action: startEditing) {
      Text(.imgly.localized("ly_img_editor_sheet_captions_row_edit"))
    }
    if !isFirst {
      Button {
        commitFocusedEdit()
        mergeWithPrevious()
      } label: {
        Text(.imgly.localized("ly_img_editor_sheet_captions_row_merge"))
      }
    }
    Button {
      commitFocusedEdit()
      Task { await onAddAfter(caption) }
    } label: {
      Text(.imgly.localized("ly_img_editor_sheet_captions_row_add_after"))
    }
    Button {
      commitFocusedEdit()
      delete()
    } label: {
      Text(.imgly.localized("ly_img_editor_sheet_captions_row_delete"))
    }
  }

  // MARK: Actions

  /// A tap on the card edits it straight away. The row actions moved to the keyboard bar, so the
  /// select-then-edit two-tap step no longer reveals anything and would just be in the way.
  private func handleTap() {
    focusedCaption = caption
  }

  /// Selects and focuses this row — the VoiceOver "Edit" action (the tap-to-edit flow is opaque to it).
  private func startEditing() {
    selectedCaption = caption
    focusedCaption = caption
  }

  /// Merges this caption with the previous one; the selection moves to whichever block survives. Guards
  /// `isMutating` at the method (not just the disabled control), so the VoiceOver action can't run it
  /// during an in-flight async op.
  private func mergeWithPrevious() {
    guard !isMutating, previousCaption != nil else { return }
    // Refuse when a *different* row is mid-edit. The survivor would then be that focused row, whose live
    // text only it can commit: the merge would join its last-committed value and then be overwritten when
    // it blurs, losing both edits. The swipe actions are withdrawn while editing for this reason, but a
    // VoiceOver custom action can still reach here.
    guard focusedCaption == nil || isFocused else { return }
    let wasEditing = isFocused
    let wasSelected = isSelected
    // Persist what is on screen first: the merge joins the engine's text, so an uncommitted edit would
    // otherwise be overwritten by the joined value.
    commitFocusedEdit()
    // Which caption survives depends on whether this row is being edited. Editing: this caption absorbs
    // the previous one, so the focused field — and with it the keyboard, caret, and action bar — is never
    // torn down. Not editing: the previous caption absorbs this one, which is the direction that leaves
    // the surviving row in place, so the list collapses cleanly instead of shuffling a row upwards.
    // Where the join lands, computed before the merge: the previous text's length, plus the separator the
    // interactor inserts only when both sides are non-empty.
    // The caret should stay on the character it was on. That character keeps its position within this
    // caption's text, which the merge pushes right by the previous text and its separator — so the same
    // sum serves both entry points: backspace-at-start (offset 0) lands exactly on the join, and the
    // toolbar merge keeps the caret mid-word where the user left it.
    if wasEditing, let previousCaption {
      let previousText = captionsInteractor.text(of: previousCaption)
      let separator = previousText.isEmpty || text.isEmpty ? 0 : 1
      let caretInThisCaption = textViewRegistry.view(for: caption)?.selectedRange.location ?? 0
      caretAfterExternalChange = previousText.utf16.count + separator + caretInThisCaption
    }
    guard let survivor = captionsInteractor.mergeWithPrevious(caption, keepingCurrent: wasEditing) else {
      caretAfterExternalChange = nil
      return
    }
    // Only carry the selection over when this row already had it. Merging from a swipe on an unselected
    // row would otherwise leave a highlighted caption behind with no keyboard and nothing being edited.
    if wasEditing || wasSelected {
      selectedCaption = survivor
    }
    onChange()
  }

  /// Deletes this caption, clearing its selection/focus state first so the header can't stay stuck on the
  /// "Done" affordance over a destroyed block. Guards `isMutating` at the method (not just the disabled
  /// menu), so the VoiceOver action can't run it during an in-flight async op.
  private func delete() {
    guard !isMutating else { return }
    if focusedCaption == caption {
      focusedCaption = nil
    }
    if selectedCaption == caption {
      selectedCaption = nil
    }
    captionsInteractor.deleteCaption(caption)
    onChange()
  }

  /// Commits this row's in-progress edit before an action acts on it. The touch flow commits on blur, but a
  /// keyboard-bar button or a VoiceOver custom action fires on a focused, mid-edit row without one — so
  /// mirror that commit here or the live edit would be lost.
  private func commitFocusedEdit() {
    if isFocused {
      commit()
    }
  }

  /// Takes the caption's text from the engine, recording what was seen so a later reload can tell an
  /// external rewrite apart from this row's own in-flight typing.
  private func load() {
    text = captionsInteractor.text(of: caption)
    loadedText = text
    didLoad = true
    externalRevision &+= 1
  }

  /// Persists the field's text on blur; skipped before the initial load or when unchanged, so an
  /// untouched session doesn't add an undo step.
  private func commit() {
    guard didLoad, captionsInteractor.text(of: caption) != text else { return }
    captionsInteractor.setText(text, of: caption)
    loadedText = text
  }
}

/// Every visible row's text view, keyed by caption.
///
/// Moving the keyboard between captions cannot go through SwiftUI state alone: state changes and the row
/// removals that follow land in the same update, in an order that isn't ours to choose, and destroying a
/// view while it is still first responder drops the keyboard. Holding the views directly lets a caller
/// hand first responder to a specific caption *before* anything is torn down.
@MainActor
final class CaptionTextViewRegistry {
  private var views: [DesignBlockID: WeakTextView] = [:]

  /// A weak handle to a row's backing `UITextView`, so the registry never keeps a torn-down row alive.
  private struct WeakTextView {
    weak var view: UITextView?
  }

  func register(_ view: UITextView, for caption: DesignBlockID) {
    views[caption] = WeakTextView(view: view)
  }

  func view(for caption: DesignBlockID) -> UITextView? {
    views[caption]?.view
  }

  /// Hands first responder to a caption's field. Returns whether it took, so a caller can fall back to
  /// driving focus through state when the row isn't on screen.
  @discardableResult
  func focus(_ caption: DesignBlockID) -> Bool {
    guard let view = view(for: caption), view.window != nil else { return false }
    return view.isFirstResponder || view.becomeFirstResponder()
  }
}
