import IMGLYEngine
import SwiftUI
import UIKit
import UniformTypeIdentifiers
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

/// The captions sheet: an "Add Captions" empty state that creates the first caption, switching to an
/// "Edit Captions" list once captions exist. The state is driven purely by the caption count (0 ↔ N),
/// including the entry point — opening the sheet with captions already present goes straight to the list,
/// with no empty-state flash.
///
/// All engine access goes through ``CaptionsInteractor``, which centralizes the caption engine rules;
/// every engine read is `isValid`-guarded so a block destroyed under a live row cannot crash the UI.
struct CaptionsSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglyEditorEnvironment) private var editorEnvironment
  /// The selected caption: accent ring, canvas selection, and a paused playhead seek that previews it.
  /// Editing implies selected.
  @State private var selectedCaption: DesignBlockID?

  // MARK: Editing state

  //
  // Two properties, each with a distinct job:
  //
  // - `focusedCaption` — *which caption is being edited*. Plain state, not `@FocusState`: the field is a
  //   UIKit text view that takes first responder itself, so there is no SwiftUI focus for `@FocusState` to
  //   track (it would reset to nil with no `.focused(_:equals:)` view to attach to). Plain state also means
  //   an assignment always sticks, including the one that ends editing as its caption is destroyed.
  // - `textViewRegistry` — *reaches UIKit*, keyed by caption: the caret and in-flight text the action bar
  //   needs, and the way first responder is handed between captions without going through an update.
  //   Not observable, so it can't drive rendering.

  /// The caption being edited. Drives the field's first responder, the action bar, and the grown detent.
  @State private var focusedCaption: DesignBlockID?
  @State private var refreshToken = 0
  /// True while an async create (which suspends on preset I/O) is in flight, so no other mutation can
  /// race it — every mutating control is disabled and re-entry is guarded.
  @State private var isMutating = false
  /// Presents the SRT/VTT document picker.
  @State private var isImportPresented = false
  /// True while a file import is in flight; drives the Import button's progress indicator.
  @State private var isImporting = false
  /// The import failure alert message; `nil` hides the alert.
  @State private var importFailureMessage: String?
  /// The caption selected on the timeline when the sheet opened; the list scrolls to it once. `nil` when
  /// opened from the dock.
  @State private var deepLinkTarget: DesignBlockID?
  /// The detent to restore after editing. While a caption is being edited the sheet grows to
  /// `.imgly.large` so the row clears the keyboard; this remembers the detent to return to.
  @State private var detentBeforeEditing: PresentationDetent?
  /// The in-flight caption generation; non-nil swaps the empty state for the "Generating Captions" view.
  /// Cancel cancels the task — nothing is created until the transcription completes and its result is
  /// imported, so cancelling leaves the scene untouched. Dismissing the sheet does *not* cancel: the task
  /// lives on ``Interactor`` and keeps running, so reopening finds it still in progress.
  private var generationTask: Task<Void, Never>? {
    get { interactor.captionsGenerationTask }
    nonmutating set { interactor.captionsGenerationTask = newValue }
  }

  /// Where the caret belongs when a caption next takes focus. A split hands over to the tail, and the
  /// caret should stay at the cut rather than jumping to the end of it.
  @State private var pendingCaret: CaptionCaret?
  /// Every row's text view, keyed by caption: the caret and in-flight text the action bar reads, and the
  /// means to hand first responder to a caption directly rather than through state.
  @State private var textViewRegistry = CaptionTextViewRegistry()

  private var captionsInteractor: CaptionsInteractor {
    CaptionsInteractor(interactor)
  }

  /// Fresh engine read each render, so the entry point reflects the real count immediately. Reading
  /// `refreshToken` establishes the dependency that re-renders the sheet after a mutation.
  private var captions: [DesignBlockID] {
    _ = refreshToken
    return captionsInteractor.captions()
  }

  /// Two-variant Add-sheet seam: the plugin variant surfaces a primary "Generate Automatically" action.
  /// A callback set via ``EditorConfiguration/Builder/captionsGeneration(_:)`` (e.g. by the auto-captions
  /// plugin) enables it; the default variant is shown otherwise.
  private var showsAutoGenerate: Bool {
    editorEnvironment.captionsGeneration != nil
  }

  var body: some View {
    TitledSheet(title) {
      content
        .background(Color(uiColor: .systemGroupedBackground))
        // The action bar rides above the keyboard as a bottom safe-area inset rather than a
        // `ToolbarItemGroup(placement: .keyboard)`: a keyboard toolbar is wrapped in system chrome, so any
        // padding lands *inside* it and only inflates the bar. Drawing the islands here — the same shape
        // the canvas text-editing `KeyboardToolbar` uses — puts the padding outside them, which is what
        // lifts the bar clear of the keyboard.
        .safeAreaInset(edge: .bottom, spacing: 0) { keyboardBar }
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) { dismissButton }
        }
        .fileImporter(isPresented: $isImportPresented, allowedContentTypes: Self.captionFileTypes) { result in
          Task { await importFile(result) }
        }
        .alert(
          Text(.imgly.localized("ly_img_editor_dialog_captions_import_error_title")),
          isPresented: .init(
            get: { importFailureMessage != nil },
            set: {
              if !$0 {
                importFailureMessage = nil
              }
            },
          ),
        ) {
          Button(role: .cancel) {} label: {
            Text(.imgly.localized("ly_img_editor_dialog_error_generic_button_dismiss"))
          }
        } message: {
          Text(importFailureMessage ?? "")
        }
    }
    // Undo/redo performed outside the sheet (e.g. the navigation-bar buttons) mutates captions without
    // going through the sheet's own actions. Funnel the engine history signal into the same reload path
    // so row text and list membership reflect it.
    .onChange(of: interactor.historyVersion) { _ in refresh() }
    // Deep-link from the timeline: select that caption on open (accent ring, scroll, playhead reveal).
    .task {
      let target = captionsInteractor.selectedCaption()
      deepLinkTarget = target
      selectedCaption = target
      syncAddSheetDetent()
    }
    // The Add (empty) state locks to a single detent; the Edit state is resizable and grows while editing.
    .onChange(of: captions.isEmpty) { _ in syncAddSheetDetent() }
    // Selecting a caption pauses playback and seeks the playhead to it; entering edit on the already-
    // selected caption doesn't re-seek (selection is unchanged).
    .onChange(of: selectedCaption) { selected in
      guard let selected else { return }
      captionsInteractor.revealCaption(selected)
    }
    // Focusing a row (by tap or after a create) selects it too, so the ring and the playhead seek follow
    // the field being edited.
    .onChange(of: focusedCaption) { focused in
      if let focused {
        selectedCaption = focused
        // Also reveal directly: when the row is already this sheet's selection, the assignment above is a
        // no-op, so nothing would re-select the caption on canvas after something else took the selection.
        // `revealCaption` skips captions that are already selected, so this can't double-seek.
        captionsInteractor.revealCaption(focused)
      }
      applyEditingChrome(focused)
    }
  }

  private var title: LocalizedStringResource {
    captions.isEmpty
      ? .imgly.localized("ly_img_editor_sheet_captions_title_add")
      : .imgly.localized("ly_img_editor_sheet_captions_title_edit")
  }

  /// The standard shared dismiss control. The end-editing check lives in the keyboard bar beside the row
  /// actions, where it sits next to the keyboard it dismisses instead of competing with the sheet's own
  /// dismiss affordance.
  private var dismissButton: some View {
    SheetDismissButton()
      .sheetDismissButtonStyle()
  }

  /// Applies the chrome that goes with editing: the grown detent that keeps the row clear of the keyboard.
  /// Driven from ``focusedCaption``'s change handler, so every path in and out of editing gets it.
  private func applyEditingChrome(_ caption: DesignBlockID?) {
    // Grow only when *entering* editing (`detentBeforeEditing == nil`), not on a row-to-row transfer —
    // otherwise a manual mid-edit resize would be yanked back to large. Restore it once editing ends.
    if caption != nil {
      if detentBeforeEditing == nil, interactor.sheet.style.detent != .imgly.large {
        detentBeforeEditing = interactor.sheet.style.detent
        interactor.sheet.style.detent = .imgly.large
      }
    } else if let previous = detentBeforeEditing {
      detentBeforeEditing = nil
      // Deleting the last caption collapses the sheet to the Add state's single detent in the same pass;
      // only restore the pre-edit detent if it's still a member of the set, so the sheet never lands on a
      // detent outside its detents.
      if interactor.sheet.style.detents.contains(previous) {
        interactor.sheet.style.detent = previous
      }
    }
  }

  // MARK: - Keyboard action bar

  /// The floating action bar shown above the keyboard while a caption is being edited. It carries the
  /// same operations Return and Backspace drive, for reaching them without the keys: Delete and the
  /// caption-to-caption arrows as icons with accessibility labels, the structural operations behind the
  /// ellipsis menu where they are named, and a labelled Done.
  @ViewBuilder private var keyboardBar: some View {
    if focusedCaption != nil {
      let bar = barIslands
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
      if #available(iOS 26.0, *), !usesLegacyDesign {
        bar
      } else {
        // No glass on legacy, so the bar needs its own opaque backing — otherwise the list scrolls
        // visibly behind it.
        bar
          .frame(maxWidth: .infinity)
          .background(Color(uiColor: .systemBackground))
      }
    }
  }

  @ViewBuilder private var barIslands: some View {
    if #available(iOS 26.0, *), !usesLegacyDesign {
      GlassEffectContainer(spacing: 8) { barIslandStack }
    } else {
      barIslandStack
    }
  }

  private var barIslandStack: some View {
    HStack(spacing: 8) {
      HStack(spacing: 4) {
        barButton(
          Image.imgly.delete,
          .imgly.localized("ly_img_editor_sheet_captions_row_delete"),
          tint: .red,
          action: deleteFocused,
        )
        structuralActionsMenu
      }
      .padding(.horizontal, 8)
      .modifier(CapsuleChrome(usesLegacyDesign: usesLegacyDesign))

      Spacer(minLength: 8)

      HStack(spacing: 4) {
        barButton(
          Image(systemName: "arrow.up"),
          .imgly.localized("ly_img_editor_sheet_captions_button_previous"),
          action: { focusCaption(offsetBy: -1) },
        )
        .disabled(focusedIsFirst)
        .opacity(focusedIsFirst ? 0.35 : 1)
        barButton(
          Image(systemName: "arrow.down"),
          .imgly.localized("ly_img_editor_sheet_captions_button_next"),
          action: { focusCaption(offsetBy: 1) },
        )
        .disabled(focusedIsLast)
        .opacity(focusedIsLast ? 0.35 : 1)
      }
      .padding(.horizontal, 8)
      .modifier(CapsuleChrome(usesLegacyDesign: usesLegacyDesign))

      // A labelled Done rather than a second blue circle: the accent checkmark competed with the panel's
      // own accent button, and this matches the canvas text-editing bar.
      Button(action: endEditing) {
        Text(.imgly.localized("ly_img_editor_sheet_captions_button_done"))
          .font(.body.weight(.semibold))
          .padding(.horizontal, 16)
          .frame(height: Self.barIslandHeight)
      }
      .buttonStyle(.plain)
      .modifier(CapsuleChrome(usesLegacyDesign: usesLegacyDesign))
    }
    .disabled(isMutating)
    // A disabled SwiftUI button does not consume its tap, and the bar floats over the list as a safe-area
    // inset — so tapping a greyed-out arrow would fall through to whatever sits beneath it, which at the
    // end of the list is Add New Caption. Catch anything the islands didn't handle.
    .contentShape(Rectangle())
    .onTapGesture {}
  }

  /// The structural operations behind an ellipsis. They are also reachable by key (Return, Backspace)
  /// and by swiping a row, so the bar only needs to keep them at hand rather than on display.
  private var structuralActionsMenu: some View {
    Menu {
      Button(action: mergeFocused) {
        Label {
          Text(.imgly.localized("ly_img_editor_sheet_captions_row_merge"))
        } icon: {
          Image(systemName: "arrow.triangle.merge")
        }
      }
      .disabled(focusedIsFirst)
      // The same split icon the inspector uses, so the two surfaces teach one symbol.
      Button(action: splitFocused) {
        Label {
          Text(.imgly.localized("ly_img_editor_sheet_captions_row_split"))
        } icon: {
          Image.imgly.split
        }
      }
      Button(action: addAfterFocused) {
        Label {
          Text(.imgly.localized("ly_img_editor_sheet_captions_row_add_after"))
        } icon: {
          Image(systemName: "plus")
        }
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.body)
        .foregroundStyle(SwiftUI.Color.primary)
        .frame(width: Self.barIslandHeight, height: Self.barIslandHeight)
        .contentShape(Rectangle())
    }
    .accessibilityLabel(Text(.imgly.localized("ly_img_editor_sheet_captions_button_more")))
  }

  private func barButton(
    _ image: Image,
    _ label: LocalizedStringResource,
    tint: SwiftUI.Color = .primary,
    action: @escaping () -> Void,
  ) -> some View {
    Button(action: action) {
      image
        .font(.body)
        .foregroundStyle(tint)
        .frame(width: Self.barIslandHeight, height: Self.barIslandHeight)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(label))
  }

  private static let barIslandHeight: CGFloat = 44

  /// Whether the caption being edited is the first one, which has nothing above it to merge into or
  /// step up to.
  private var focusedIsFirst: Bool {
    guard let focusedCaption else { return true }
    return captions.first == focusedCaption
  }

  /// Whether the caption being edited is the last one, which has nothing below it to step down to.
  private var focusedIsLast: Bool {
    guard let focusedCaption else { return true }
    return captions.last == focusedCaption
  }

  /// Hands the keyboard to the caption `offsetBy` rows away, committing the current text first so
  /// stepping off a row can't drop an edit that was never typed back into the engine.
  private func focusCaption(offsetBy step: Int) {
    guard !isMutating,
          let focusedCaption,
          let index = captions.firstIndex(of: focusedCaption),
          case let target = index + step,
          captions.indices.contains(target) else { return }
    _ = commitFocusedText()
    beginEditing(captions[target])
  }

  @ViewBuilder private var content: some View {
    if captions.isEmpty {
      if generationTask != nil {
        CaptionsGeneratingView { generationTask?.cancel() }
      } else {
        CaptionsEmptyStateView(
          showsAutoGenerate: showsAutoGenerate,
          canGenerate: captionsInteractor.hasAudioVisualContent(),
          isMutating: isMutating,
          isImporting: isImporting,
          onGenerate: generateCaptions,
          onCreate: addCaption,
          onImport: { isImportPresented = true },
        )
      }
    } else {
      CaptionsListView(
        captions: captions,
        captionsInteractor: captionsInteractor,
        selectedCaption: $selectedCaption,
        focusedCaption: $focusedCaption,
        deepLinkTarget: deepLinkTarget,
        reloadToken: refreshToken,
        isMutating: isMutating,
        onChange: refresh,
        onAdd: addCaption,
        onAddAfter: addCaptionAfter,
        pendingCaret: pendingCaret,
        textViewRegistry: textViewRegistry,
        onSplitAtCaret: splitCaption,
        // Moves editing to a caption, placing the caret at an offset — used after a backspace deletes
        // an empty caption, so editing continues at the end of the one above.
        onEditCaption: { beginEditing($0, caret: $1) },
        // A caret request has been applied by its row, so it must not be applied again.
        onCaretApplied: { pendingCaret = nil },
      )
    }
  }

  private func refresh() {
    refreshToken &+= 1
    // Undo/redo can destroy the caption the selection or focus points at — drop stale references.
    let current = captionsInteractor.captions()
    if let selected = selectedCaption, !current.contains(selected) {
      selectedCaption = nil
    }
    if let focused = focusedCaption, !current.contains(focused) {
      focusedCaption = nil
    }
  }

  /// The Add (empty) state locks the sheet to one non-resizable detent; the Edit state restores the
  /// resizable set (and the grow-while-editing `onChange` drives the detent within it). Preserving the
  /// current detent while expanding keeps this independent of the order it runs relative to that grow.
  private func syncAddSheetDetent() {
    if captions.isEmpty {
      if interactor.sheet.style.detents.count > 1 {
        interactor.sheet.style = .only(detent: .imgly.small)
      }
    } else if interactor.sheet.style.detents.count == 1 {
      interactor.sheet.style = .default(
        detent: interactor.sheet.style.detent,
        detents: [.imgly.small, .imgly.medium, .imgly.large],
      )
    }
  }

  private func addCaption() async {
    guard !isMutating else { return }
    isMutating = true
    // Not guarded: adding is also reachable with nothing focused, where there is no text to keep.
    _ = commitFocusedText()
    let new = await captionsInteractor.createCaption()
    refresh()
    beginEditing(new)
    isMutating = false
  }

  private func addCaptionAfter(_ caption: DesignBlockID) async {
    guard !isMutating else { return }
    isMutating = true
    _ = commitFocusedText()
    let new = await captionsInteractor.addCaptionAfter(caption)
    refresh()
    beginEditing(new)
    isMutating = false
  }

  // MARK: - Keyboard bar actions (on the caption being edited)

  /// The edited row's text view — the caret to act on, and the in-flight text to commit. Asking the
  /// registry for a specific caption means it can't answer with a neighbour's field.
  private var focusedField: UITextView? {
    focusedCaption.flatMap { textViewRegistry.view(for: $0) }
  }

  /// Persists the focused field's live text. The row commits on blur, but a bar action mutates while the
  /// field is still first responder — the engine would otherwise be read at its last-committed value.
  /// - Returns: `false` when the field can't be reached, which means the live text can't be saved; callers
  ///   must abort rather than mutate, or the edit would be destroyed by the reload that follows.
  @discardableResult
  private func commitFocusedText() -> Bool {
    guard let focusedCaption, let live = focusedField?.text else { return false }
    if captionsInteractor.text(of: focusedCaption) != live {
      captionsInteractor.setText(live, of: focusedCaption)
    }
    return true
  }

  /// Merges the edited caption into the one above it. `keepingCurrent` keeps the focused block alive, so
  /// the field — and with it the keyboard and this bar — is never torn down.
  private func mergeFocused() {
    guard !isMutating, let focusedCaption, !focusedIsFirst, commitFocusedText() else { return }
    // Keep the caret on the character it was on. That character keeps its place within this caption's
    // text, which the merge pushes right by the previous caption's text and the separator between them —
    // so someone merging from the end of a caption stays at the end, not thrown to the front of the join.
    let caret = mergedCaretOffset(for: focusedCaption)
    guard captionsInteractor.mergeWithPrevious(focusedCaption, keepingCurrent: true) != nil else { return }
    // Set before the refresh, so the row applies it on the same pass that re-reads the joined text.
    pendingCaret = caret.map { CaptionCaret(caption: focusedCaption, offset: $0) }
    refresh()
  }

  /// Where the caret should land after `caption` absorbs the one above it.
  private func mergedCaretOffset(for caption: DesignBlockID) -> Int? {
    guard let index = captions.firstIndex(of: caption), index > 0 else { return nil }
    let previousText = captionsInteractor.text(of: captions[index - 1])
    let currentText = captionsInteractor.text(of: caption)
    let separator = previousText.isEmpty || currentText.isEmpty ? 0 : 1
    let caretHere = focusedField?.selectedRange.location ?? currentText.utf16.count
    return previousText.utf16.count + separator + caretHere
  }

  /// Splits the edited caption at the caret, moving editing to the tail. A caret at the very end has
  /// nothing to divide — and that is where entering a row parks it — so append a caption there instead,
  /// matching web, rather than leaving the button inert.
  private func splitFocused() {
    guard !isMutating, let focusedCaption, let textView = focusedField else { return }
    let caretOffset = textView.selectedRange.location
    guard commitFocusedText() else { return }
    guard caretOffset < (textView.text as NSString).length else {
      Task { await addCaptionAfter(focusedCaption) }
      return
    }
    splitCaption(focusedCaption, atCaret: caretOffset)
  }

  /// Splits a caption at an explicit caret offset — used wherever the caret is already known, whether
  /// Return was pressed mid-text or the bar's Split button read it off the field.
  private func splitCaption(_ caption: DesignBlockID, atCaret caretUTF16: Int) {
    guard !isMutating, let new = captionsInteractor.splitCaption(caption, at: caretUTF16) else { return }
    // `refresh()` also makes the head re-read: its field still holds the whole pre-split text.
    refresh()
    // Caret at the start of the tail — the same place on screen the cut was made, so typing carries on
    // where it left off instead of jumping to the end.
    beginEditing(new, caret: 0)
  }

  private func addAfterFocused() {
    guard let focusedCaption, commitFocusedText() else { return }
    Task { await addCaptionAfter(focusedCaption) }
  }

  private func deleteFocused() {
    guard !isMutating, let caption = focusedCaption else { return }
    // The field's text is local to the row until it is written back, so deleting without committing first
    // hands undo the caption's older text.
    _ = commitFocusedText()
    if let successor = captionSucceeding(caption) {
      // Take first responder *before* the row is deleted, the same way backspacing an empty caption
      // does. State alone isn't enough: the assignment and this row's removal land in the same update,
      // and if the removal wins the keyboard goes with it.
      textViewRegistry.focus(successor.caption)
      beginEditing(successor.caption, caret: successor.caret)
    } else {
      focusedCaption = nil
      selectedCaption = nil
    }
    captionsInteractor.deleteCaption(caption)
    refresh()
  }

  /// The caption that should take the keyboard once `caption` is deleted, and where its caret belongs.
  ///
  /// The one below, so deleting reads downwards through the list. The last caption has nothing below it
  /// and falls back to the one above, entered at the end of its text; deleting the only caption returns
  /// `nil` and the sheet collapses back to its Add state.
  private func captionSucceeding(_ caption: DesignBlockID) -> (caption: DesignBlockID, caret: Int)? {
    let captions = captions
    guard let index = captions.firstIndex(of: caption) else { return nil }
    if captions.indices.contains(index + 1) {
      return (captions[index + 1], 0)
    }
    guard captions.indices.contains(index - 1) else { return nil }
    let previous = captions[index - 1]
    return (previous, captionsInteractor.text(of: previous).utf16.count)
  }

  /// Ends editing. The field commits its own text on blur, so this only has to drop focus and selection.
  private func endEditing() {
    focusedCaption = nil
    selectedCaption = nil
  }

  // MARK: - Generate (auto-captions)

  /// Runs the callback configured via ``EditorConfiguration/Builder/captionsGeneration(_:)`` and imports
  /// its result through the same pipeline as a file import — so styling, track replacement, and the
  /// single undo step behave identically. Nothing is created until the callback returns, which makes
  /// Cancel side-effect free. A `nil` result means the audio held no speech.
  private func generateCaptions() {
    guard !isMutating, generationTask == nil,
          let generate = editorEnvironment.captionsGeneration,
          let engine = interactor.engine else { return }
    isMutating = true
    generationTask = Task {
      defer {
        generationTask = nil
        isMutating = false
      }
      do {
        guard let url = try await generate(engine) else {
          // A callback is free to read "return `nil` when there is nothing to transcribe" as covering
          // cancellation, so stay silent whenever the user cancelled — as the generic catch below does.
          guard !Task.isCancelled else { return }
          reportGenerationFailure("ly_img_editor_sheet_captions_generate_error_no_speech")
          return
        }
        defer { try? FileManager.default.removeItem(at: url) }
        try Task.checkCancellation()
        try await captionsInteractor.importCaptions(from: url)
        // The import is not cancellable; if the user cancelled while it committed, revert it so Cancel
        // leaves the scene untouched, as documented.
        if Task.isCancelled {
          captionsInteractor.revertLastStep()
        }
        refresh()
      } catch is CancellationError {
        // Cancelled — fall back to the Add state silently.
      } catch {
        // A cancelled network request surfaces as the transport's own error (e.g. `URLError.cancelled`)
        // rather than `CancellationError` — stay silent whenever the user cancelled.
        guard !Task.isCancelled else { return }
        reportGenerationFailure("ly_img_editor_sheet_captions_generate_error_generic")
      }
    }
  }

  /// Surfaces a generation failure through the editor's global error alert rather than one owned by this
  /// sheet. Generation outlives the sheet, so a failure can land while it is closed — an alert bound to
  /// sheet state would sit unseen until the user happened to reopen, or never be seen at all.
  private func reportGenerationFailure(_ key: String.LocalizationValue) {
    interactor.handleError(Error(errorDescription: String(localized: .imgly.localized(key))))
  }

  // MARK: - Import (SRT/VTT)

  /// The importable file types — SRT and VTT only. `.vtt` has Apple's native `org.w3.webvtt` type; `.srt`
  /// has none, so it resolves from the extension (the app's declared type when one ships, else a dynamic
  /// type). Not widened to `.plainText`/`.text`, which would match any text file.
  private static let captionFileTypes: [UTType] = ["srt", "vtt"].compactMap { UTType(filenameExtension: $0) }

  private func importFile(_ result: Result<URL, Swift.Error>) async {
    guard !isMutating else { return }
    isMutating = true
    isImporting = true
    defer {
      isMutating = false
      isImporting = false
    }
    do {
      let url = try stagedFileForImport(result.get())
      defer { try? FileManager.default.removeItem(at: url) }
      try await captionsInteractor.importCaptions(from: url)
      refresh()
    } catch {
      importFailureMessage = alertMessage(for: error)
    }
  }

  /// Copies the picked file to a temporary location the engine can read after the security-scoped access
  /// window closes (extension kept for format detection). A `false` from
  /// `startAccessingSecurityScopedResource()` isn't fatal — some URLs need no scoping — so it copies anyway.
  private func stagedFileForImport(_ picked: URL) throws -> URL {
    let didStartAccessing = picked.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing {
        picked.stopAccessingSecurityScopedResource()
      }
    }
    let url = try FileManager.default.getUniqueCacheURL()
      .appendingPathExtension(picked.pathExtension)
    try FileManager.default.copyItem(at: picked, to: url)
    return url
  }

  /// Maps the import errors to alert copy. `createCaptionsFromURI` checks the resource and MIME before
  /// parsing, so it reports them as `ENCODE.*` codes; the parser's `UTILS.CAPTION_*` codes are mapped too.
  /// Unrecognized codes fall back to the engine's message.
  private func alertMessage(for error: Swift.Error) -> String {
    guard let engineError = EngineError(error) else { return error.localizedDescription }
    return switch engineError.catalogCode {
    case .utilsCaptionParseEmpty, .encodeResourceDataEmpty:
      String(localized: .imgly.localized("ly_img_editor_dialog_captions_import_error_parse_empty"))
    case .encodeMimeTypeInvalid, .utilsCaptionUnsupportedMime:
      String(localized: .imgly.localized("ly_img_editor_dialog_captions_import_error_unsupported_format"))
    case .utilsCaptionUtf16InvalidSize:
      String(localized: .imgly.localized("ly_img_editor_dialog_captions_import_error_file_damaged"))
    case .encodeResourceLoadFailedWithReason, .utilsCaptionDataUnavailable:
      String(localized: .imgly.localized("ly_img_editor_dialog_captions_import_error_file_unreadable"))
    default:
      engineError.displayMessage
    }
  }

  /// Selects a caption and focuses its field, optionally parking the caret at an explicit offset.
  private func beginEditing(_ caption: DesignBlockID?, caret: Int? = nil) {
    guard let caption else { return }
    pendingCaret = caret.map { CaptionCaret(caption: caption, offset: $0) }
    selectedCaption = caption
    // Assigned straight away. Every caller passes a caption the engine already holds — `captions` reads
    // it live, and create/add/split all attach before returning — so its row either exists or is about
    // to, and the editor retries until the field is in a window. Deferring would leave a turn with no
    // first responder, which reads as the keyboard closing and reopening.
    focusedCaption = caption
  }
}

// MARK: - Capsule chrome

/// A full-width capsule background: the app's Liquid Glass (matching the keyboard toolbar's
/// `IslandChrome`). Falls back to a plain material capsule before iOS 26 / in compatibility mode.
private struct CapsuleChrome: ViewModifier {
  let usesLegacyDesign: Bool

  func body(content: Content) -> some View {
    if #available(iOS 26.0, *), !usesLegacyDesign {
      content.glassEffect(.regular.interactive(), in: Capsule())
    } else {
      content.background(Color(uiColor: .secondarySystemBackground), in: Capsule())
    }
  }
}

/// A full-width capsule button with SF Pro SemiBold text on a solid fill.
/// While `isLoading`, the label yields to a progress indicator (keeping the capsule's size).
private struct CaptionCapsuleButton: View {
  let title: LocalizedStringResource
  var tint: SwiftUI.Color = .primary
  var isEnabled: Bool = true
  var isLoading: Bool = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.body.weight(.semibold))
        .foregroundStyle(tint)
        .opacity(isLoading ? 0 : 1)
        .overlay {
          if isLoading {
            ProgressView()
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        // The same fill the list's footer buttons use: without it these read as bare text on the
        // sheet's grouped background, which is the identical colour in light mode.
        .background(SwiftUI.Color(uiColor: .secondarySystemFill), in: Capsule())
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
    .opacity(isEnabled || isLoading ? 1 : 0.4)
  }
}

/// The primary blue capsule CTA (Generate Automatically, in the plugin variant's empty state).
private struct CaptionProminentButton: View {
  let title: LocalizedStringResource
  var isEnabled: Bool = true
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.body.weight(.semibold))
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .buttonBorderShape(.capsule)
    .controlSize(.large)
    .disabled(!isEnabled)
  }
}

// MARK: - Empty state ("Add Captions")

private struct CaptionsEmptyStateView: View {
  /// The plugin variant surfaces the primary "Generate Automatically" action.
  let showsAutoGenerate: Bool
  /// Disables Generate when the scene has no audio or video content to transcribe.
  let canGenerate: Bool
  /// Disables Create and Import while a mutation is in flight.
  let isMutating: Bool
  /// Shows the Import button's progress indicator.
  let isImporting: Bool
  /// Starts automatic caption generation (swaps this view for the generating state).
  let onGenerate: () -> Void
  /// Creates the first caption (and focuses it); `async` because default styling fetches a preset.
  let onCreate: () async -> Void
  /// Presents the SRT/VTT document picker.
  let onImport: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      if showsAutoGenerate {
        // Only the plugin's automatic transcription gets the primary/CTA treatment.
        CaptionProminentButton(
          title: .imgly.localized("ly_img_editor_sheet_captions_button_generate"),
          isEnabled: canGenerate && !isMutating,
          action: onGenerate,
        )
      }

      CaptionCapsuleButton(
        title: .imgly.localized("ly_img_editor_sheet_captions_button_create"),
        isEnabled: !isMutating,
      ) {
        Task { await onCreate() }
      }

      CaptionCapsuleButton(
        title: .imgly.localized("ly_img_editor_sheet_captions_button_import"),
        isEnabled: !isMutating,
        isLoading: isImporting,
        action: onImport,
      )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

// MARK: - Generating state ("Generating Captions")

/// The loading state shown while automatic caption generation is in flight: a spinner with a
/// "Generating Captions" label where the empty state's actions were, and a Cancel button.
private struct CaptionsGeneratingView: View {
  /// Cancels the in-flight generation, returning to the Add state.
  let onCancel: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      VStack(spacing: 12) {
        ProgressView()
          .controlSize(.large)
        Text(.imgly.localized("ly_img_editor_sheet_captions_generating"))
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 24)

      CaptionCapsuleButton(
        title: .imgly.localized("ly_img_editor_button_cancel"),
        action: onCancel,
      )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

// MARK: - List ("Edit Captions")

private struct CaptionsListView: View {
  @State private var isDeleteAllConfirmationPresented = false
  let captions: [DesignBlockID]
  let captionsInteractor: CaptionsInteractor
  @Binding var selectedCaption: DesignBlockID?
  @Binding var focusedCaption: DesignBlockID?
  /// The caption to scroll to once on open (the timeline selection).
  let deepLinkTarget: DesignBlockID?
  let reloadToken: Int
  /// True while an async create is in flight — disables the footer actions so they can't race it.
  let isMutating: Bool
  /// Called after a delete/merge so the parent can refresh.
  let onChange: () -> Void
  /// Appends a new caption after the last one and edits it.
  let onAdd: () async -> Void
  /// Inserts a new caption after the given one and edits it.
  let onAddAfter: (DesignBlockID) async -> Void
  /// Where the caret belongs when its caption takes focus, if one was requested.
  let pendingCaret: CaptionCaret?
  /// Every row's text view, for direct focus hand-off.
  let textViewRegistry: CaptionTextViewRegistry
  /// Splits a caption at a caret offset and edits the tail.
  let onSplitAtCaret: (DesignBlockID, Int) -> Void
  /// Moves editing to a caption with the caret at an offset.
  let onEditCaption: (DesignBlockID, Int) -> Void
  /// Clears the caret request once a row has applied it.
  let onCaretApplied: () -> Void

  private let rowInsets = EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16)

  var body: some View {
    ScrollViewReader { proxy in
      List {
        ForEach(captions, id: \.self) { caption in
          CaptionRowView(
            caption: caption,
            previousCaption: previousCaption(of: caption),
            captionsInteractor: captionsInteractor,
            selectedCaption: $selectedCaption,
            focusedCaption: $focusedCaption,
            reloadToken: reloadToken,
            isMutating: isMutating,
            onChange: onChange,
            onAddAfter: onAddAfter,
            onSplitAtCaret: onSplitAtCaret,
            onEditCaption: onEditCaption,
            onCaretApplied: onCaretApplied,
            pendingCaret: pendingCaret,
            textViewRegistry: textViewRegistry,
          )
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
          .listRowInsets(rowInsets)
        }

        // Footer buttons render at the end of the list, not pinned.
        // Deliberately not the prominent style: a filled accent button dominated the panel and clashed
        // with the accent controls above it. Same capsule as Delete All, tinted rather than filled.
        CaptionCapsuleButton(
          title: .imgly.localized("ly_img_editor_sheet_captions_button_add"),
          tint: .accentColor,
          isEnabled: !isMutating,
        ) {
          Task { await onAdd() }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))

        CaptionCapsuleButton(
          title: .imgly.localized("ly_img_editor_sheet_captions_button_delete_all"),
          tint: .red,
          isEnabled: !isMutating,
        ) {
          // Resign first so the dialog isn't presented over a live keyboard.
          focusedCaption = nil
          isDeleteAllConfirmationPresented = true
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 16, trailing: 16))
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      // Confirmed because it discards every caption at once, unlike the per-row Delete. It is a single
      // undo step, so the copy doesn't claim otherwise.
      .alert(
        Text(.imgly.localized("ly_img_editor_dialog_captions_delete_all_title")),
        isPresented: $isDeleteAllConfirmationPresented,
      ) {
        Button(role: .destructive) {
          selectedCaption = nil
          captionsInteractor.deleteAllCaptions()
          onChange()
        } label: {
          Text(.imgly.localized("ly_img_editor_dialog_captions_delete_all_button_confirm"))
        }
        Button(role: .cancel) {} label: {
          Text(.imgly.localized("ly_img_editor_dialog_captions_delete_all_button_dismiss"))
        }
      } message: {
        Text(.imgly.localized("ly_img_editor_dialog_captions_delete_all_text"))
      }
      // Tapping outside any row — the insets, gaps, or trailing space — clears the selection. Row taps sit
      // deeper in the hierarchy, so they win over this gesture.
      .onTapGesture {
        focusedCaption = nil
        selectedCaption = nil
      }
      // A constant gap above the keyboard; SwiftUI's automatic avoidance handles the rest.
      .safeAreaInset(edge: .bottom, spacing: 0) {
        Color.clear.frame(height: 24)
      }
      // Keyboard avoidance scrolls a focused field into view, but only once the field exists: a row the
      // list hasn't realized yet never builds one, so nothing can take first responder and the caret
      // stays where it was. Stepping past the visible rows — a handful, with the keyboard up — would
      // otherwise look like the arrows had stopped working. The default anchor scrolls the least amount
      // needed, so a row already on screen doesn't move and avoidance keeps the field it has.
      .onChange(of: focusedCaption) { focused in
        guard let focused else { return }
        proxy.scrollTo(focused)
      }
      // Scroll the timeline-selected caption into view on open. Keyed on the target so it re-fires once
      // the parent `.task` assigns it (a bare `.task` could run first, read nil, and never retry). The
      // delay lets rows lay out.
      .task(id: deepLinkTarget) {
        guard let target = deepLinkTarget, captions.contains(target) else { return }
        try? await Task.sleep(for: .milliseconds(50))
        withAnimation { proxy.scrollTo(target, anchor: .center) }
      }
    }
  }

  /// The caption before the given one, if any — the merge focus target.
  private func previousCaption(of caption: DesignBlockID) -> DesignBlockID? {
    guard let index = captions.firstIndex(of: caption), index > 0 else { return nil }
    return captions[index - 1]
  }
}
