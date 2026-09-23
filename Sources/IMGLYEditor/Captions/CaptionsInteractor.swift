import CoreMedia
import Foundation
import IMGLYEngine
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

/// Domain layer for the caption editing surface: the single place that talks to the engine for captions.
///
/// The engine rules it centralizes, so no view has to:
/// - **Never loop a style setter across captions** — apply a preset to ONE caption via
///   ``IMGLYEngine/AssetAPI/applyToBlock(sourceID:assetResult:block:)``; the engine syncs the siblings.
/// - **Undo a preset's re-framing with a *scale*, never by writing the box back** — a preset writes the box
///   *and* the font size (plus the stroke, shadow, padding, and radius derived from it), so restoring the
///   box alone leaves a big rectangle around tiny text. See ``restoreCaptionBox(_:of:by:height:)``.
/// - **Attach before styling** — the engine's style sync only reaches scene-attached blocks.
/// - **Add a caption by *copying* its neighbour, never by creating and styling a blank one** — attaching a
///   block replays its synced properties one at a time, which drifts a rotated caption. See
///   ``detachedCopy(_:of:at:duration:)``.
/// - **Guard every engine read with `isValid`** — a merge or delete can destroy a block a row still holds.
/// - **Caption text lives under `caption/*`, not `text/*`.**
///
/// Wraps ``Interactor`` for engine access, undo, and error handling. Every mutation does all of its work and
/// then a single ``Interactor/addUndoStep()``, so one undo reverts the whole operation.
@MainActor
struct CaptionsInteractor {
  private let interactor: Interactor

  init(_ interactor: Interactor) {
    self.interactor = interactor
  }

  private enum Constants {
    static let defaultCaptionDuration = 3.0
    /// Mirrors `TimelineConfiguration.minCaptionClipDuration`, which the interactor cannot read: anything
    /// shorter is a clip the timeline will not let the user grab back.
    static let minimumCaptionDuration = 0.1
    static let presetsSourceID = "ly.img.caption.presets"
    static let defaultPresetID = "ly.img.caption.presets.outline"
    static let textProperty = "caption/text"
    /// Stamped on the *track*, not the caption, so it is part of scene + undo state.
    static let appliedPresetMetadataKey = "ly.img.caption.appliedPresetID"
    static let sizeRestoreEpsilon: Float = 0.001
  }

  /// A layout length as the engine stores it. Value and mode always travel together: a mode setter only
  /// swaps the unit, never converts the value.
  private typealias LayoutLength = (value: Float, mode: SizeMode)

  private var engine: Engine? {
    interactor.engine
  }

  // MARK: - Reads (every engine read guarded by `isValid`)

  /// The captions on the current page's caption track, in track order. Empty when there is no track yet.
  func captions() -> [DesignBlockID] {
    guard let engine, let track = existingCaptionTrack() else { return [] }
    return (try? captionChildren(engine, of: track)) ?? []
  }

  /// The text of a caption, or an empty string if the block is no longer valid.
  func text(of caption: DesignBlockID) -> String {
    guard let engine, engine.block.isValid(caption) else { return "" }
    return (try? engine.block.getString(caption, property: Constants.textProperty)) ?? ""
  }

  /// The caption currently selected on the timeline, if any — lets the sheet deep-link to that row.
  func selectedCaption() -> DesignBlockID? {
    guard let engine else { return nil }
    return engine.block.findAllSelected().first { engine.block.isValid($0) && isCaption($0) }
  }

  /// Whether the scene has any audio or video to transcribe — drives the "Generate Automatically" action.
  /// Mutedness is left to the generation callback, which skips muted blocks itself.
  func hasAudioVisualContent() -> Bool {
    guard let engine, let page = currentPage() else { return false }
    // Audio by type: a voiceover's kind is `voiceover`, not `audio`. Video by fill type. Scoped to the
    // current page, as the generator is, so the action never offers a page the user is not on.
    let audio = (try? engine.block.find(byType: .audio)) ?? []
    let video = ((try? engine.block.find(byType: .graphic)) ?? []).filter { isVideoFootage($0, engine: engine) }
    return (audio + video).contains { isDescendant($0, of: page, engine: engine) }
  }

  /// A graphic with a video fill, except an animated sticker. GIF and APNG count: the generator drops them
  /// for having no audio track.
  private func isVideoFootage(_ block: DesignBlockID, engine: Engine) -> Bool {
    guard (try? engine.block.supportsFill(block)) == true,
          let fill = try? engine.block.getFill(block),
          (try? engine.block.getType(fill)) == FillType.video.rawValue else { return false }
    let kind: BlockKind? = try? engine.block.getKind(block)
    return kind != .key(.animatedSticker)
  }

  /// Whether `block` sits anywhere below `page`, directly or nested in one of its tracks.
  private func isDescendant(_ block: DesignBlockID, of page: DesignBlockID, engine: Engine) -> Bool {
    var current = block
    while let parent = try? engine.block.getParent(current) {
      if parent == page {
        return true
      }
      current = parent
    }
    return false
  }

  // MARK: - Selection and playback

  /// Makes a caption the canvas selection and previews it: playback pauses and the playhead moves to the
  /// caption's start, so canvas, timeline, and inspector all follow the row being edited (as on web).
  ///
  /// A no-op for an already selected caption, so re-entering a row doesn't yank the playhead back to its
  /// start and this stays safe to call on every focus change.
  func revealCaption(_ caption: DesignBlockID) {
    guard let engine, engine.block.isValid(caption),
          !((try? engine.block.isSelected(caption)) ?? false) else { return }
    do {
      try engine.block.select(caption)
    } catch {
      interactor.handleError(error)
    }
    interactor.pauseIfNeeded()
    let offset = (try? engine.block.getTimeOffset(caption)) ?? 0
    interactor.setPlayheadPosition(CMTime(seconds: offset))
  }

  // MARK: - Mutations (each a single undo step)

  /// Appends a caption to the track and moves the playhead to it: a *copy* of the last caption when there is
  /// one — so it arrives already sized, rotated, placed, styled and animated like the track it joins — or,
  /// on an empty track, a fresh caption styled with the default preset, centered, and starting at 0.
  ///
  /// All work — including the async preset apply — completes before the single undo step, so one undo
  /// removes the caption *and* the track it created.
  /// - Returns: The created caption, so the caller can put it straight into edit mode.
  @discardableResult
  func createCaption() async -> DesignBlockID? {
    guard let engine, let page = currentPage() else { return nil }
    var createdTrack: DesignBlockID?
    var createdCaption: DesignBlockID?
    do {
      let track: DesignBlockID
      if let existing = existingCaptionTrack() {
        track = existing
      } else {
        // `captionTrack` initializes `automaticallyManageBlockOffsets = false` engine-side (gaps preserved).
        track = try engine.block.create(.captionTrack)
        // Remembered before it is attached, so a failure to attach still rolls the orphan back.
        createdTrack = track
        try engine.block.appendChild(to: page, child: track)
      }

      let caption: DesignBlockID
      // Read before the new block is attached, so it can't resolve to the new caption itself.
      if let last = (try? captionChildren(engine, of: track))?.last {
        // Start right after the last caption, keeping the track contiguous and non-overlapping.
        let end = ((try? engine.block.getTimeOffset(last)) ?? 0) + ((try? engine.block.getDuration(last)) ?? 0)
        caption = try detachedCopy(engine, of: last, at: end)
        createdCaption = caption
        try engine.block.appendChild(to: track, child: caption)
      } else {
        caption = try engine.block.create(.caption)
        createdCaption = caption
        try engine.block.appendChild(to: track, child: caption) // attach before styling
        try engine.block.setDuration(caption, duration: Constants.defaultCaptionDuration)
        // No time offset: the track's first caption keeps the engine's default of 0 and the playhead comes
        // to it, rather than the caption being created wherever the playhead happens to sit.
        await applyDefaultStyling(engine, to: caption)
        // Centering fans out across the track (see `centerCaption(_:_:)`), which is safe only here: this
        // caption is the track's only one, so there is no placement to throw away.
        try centerCaption(engine, caption)
      }

      try engine.block.setPlaybackTime(page, time: (try? engine.block.getTimeOffset(caption)) ?? 0)

      interactor.addUndoStep()
      return caption
    } catch {
      // Destroy the track only when this operation created it — an existing one keeps its other captions.
      if let createdTrack, engine.block.isValid(createdTrack) {
        try? engine.block.destroy(createdTrack)
      }
      if let createdCaption, engine.block.isValid(createdCaption) {
        try? engine.block.destroy(createdCaption)
      }
      interactor.handleError(error)
      return nil
    }
  }

  /// Sets the text of a caption. No-op if the block is no longer valid.
  func setText(_ text: String, of caption: DesignBlockID) {
    guard let engine, engine.block.isValid(caption) else { return }
    do {
      try engine.block.setString(caption, property: Constants.textProperty, value: text)
      interactor.addUndoStep()
    } catch {
      interactor.handleError(error)
    }
  }

  /// Deletes a caption, removing the caption track too if it becomes empty. One undo step.
  func deleteCaption(_ caption: DesignBlockID) {
    guard let engine, engine.block.isValid(caption) else { return }
    do {
      let track = existingCaptionTrack()
      try engine.block.destroy(caption)
      if let track, engine.block.isValid(track),
         (try? engine.block.getChildren(track))?.isEmpty ?? true {
        try engine.block.destroy(track)
      }
      interactor.addUndoStep()
    } catch {
      interactor.handleError(error)
    }
  }

  // MARK: - Editing operations

  /// Inserts a copy of the given caption immediately after it, sized to the gap that follows so the rest of
  /// the track stays where it is. See ``detachedCopy(_:of:at:duration:)`` for why a copy. One undo step.
  /// - Returns: The created caption, so the caller can put it straight into edit mode.
  @discardableResult
  func addCaptionAfter(_ caption: DesignBlockID) async -> DesignBlockID? {
    guard let engine, engine.block.isValid(caption), let track = existingCaptionTrack() else { return nil }
    var createdCaption: DesignBlockID?
    do {
      let siblings = try captionChildren(engine, of: track)
      guard let index = siblings.firstIndex(of: caption) else { return nil }
      let start = (try? engine.block.getTimeOffset(caption)) ?? 0
      let duration = (try? engine.block.getDuration(caption)) ?? 0
      let end = start + duration
      let next = siblings.indices.contains(index + 1) ? siblings[index + 1] : nil
      let nextStart = next.flatMap { try? engine.block.getTimeOffset($0) }

      let new = try detachedCopy(
        engine,
        of: caption,
        at: end,
        duration: Self.insertedDuration(startingAt: end, before: nextStart),
      )
      createdCaption = new
      try engine.block.insertChild(into: track, child: new, at: index + 1)
      interactor.addUndoStep()
      return new
    } catch {
      if let createdCaption, engine.block.isValid(createdCaption) {
        try? engine.block.destroy(createdCaption)
      }
      interactor.handleError(error)
      return nil
    }
  }

  /// Merges a caption with its previous sibling: text is space-joined and the merged caption spans from the
  /// previous start to this one's end, swallowing any gap. No-op for the first caption. One undo step.
  ///
  /// Which block survives is the caller's choice, because it decides which SwiftUI row lives:
  /// - `keepingCurrent: true` keeps `caption` — use it while editing, so the focused text field (and with
  ///   it the keyboard, caret, and action bar) is never torn down.
  /// - `keepingCurrent: false` keeps the previous block, so the list collapses in place instead of
  ///   shuffling a row up into the freed slot.
  ///
  /// - Returns: The surviving caption, or `nil` if nothing merged.
  @discardableResult
  func mergeWithPrevious(_ caption: DesignBlockID, keepingCurrent: Bool) -> DesignBlockID? {
    guard let engine, engine.block.isValid(caption), let track = existingCaptionTrack() else { return nil }
    do {
      let siblings = try captionChildren(engine, of: track)
      guard let index = siblings.firstIndex(of: caption), index > 0 else { return nil }
      let previous = siblings[index - 1]

      let previousText = (try? engine.block.getString(previous, property: Constants.textProperty)) ?? ""
      let currentText = (try? engine.block.getString(caption, property: Constants.textProperty)) ?? ""
      let joined = [previousText, currentText].filter { !$0.isEmpty }.joined(separator: " ")

      let previousStart = (try? engine.block.getTimeOffset(previous)) ?? 0
      let previousDuration = (try? engine.block.getDuration(previous)) ?? 0
      let currentStart = (try? engine.block.getTimeOffset(caption)) ?? 0
      let currentDuration = (try? engine.block.getDuration(caption)) ?? 0
      // `max` keeps the previous duration when the current caption is nested inside it — and, unlike
      // clamping the gap to 0, never overcounts when the two overlap.
      let mergedDuration = max(previousDuration, (currentStart + currentDuration) - previousStart)

      // Survivor first, absorbed sibling destroyed last, so a throw part-way leaves both blocks intact
      // instead of losing one's text. They overlap in between, which the caption track tolerates.
      let survivor = keepingCurrent ? caption : previous
      try engine.block.setString(survivor, property: Constants.textProperty, value: joined)
      try engine.block.setTimeOffset(survivor, offset: previousStart)
      try engine.block.setDuration(survivor, duration: mergedDuration)
      try engine.block.destroy(keepingCurrent ? previous : caption)
      interactor.addUndoStep()
      return survivor
    } catch {
      interactor.handleError(error)
      return nil
    }
  }

  /// Splits a caption in two at a cursor offset: the text before the cursor stays, the text after it moves
  /// to a new caption inserted immediately after, and the duration is divided in proportion to the character
  /// split — the caret carries no time of its own.
  ///
  /// Matching web, neither side is trimmed: a space at the split point stays on the new caption. One undo
  /// step.
  /// - Parameters:
  ///   - caption: The caption to split.
  ///   - cursorOffset: The split point, as the UTF-16 offset UIKit reports for the caret.
  /// - Returns: The new caption holding the text after the cursor, or `nil` — leaving the scene untouched —
  ///   when the offset doesn't divide the text in two (at either end, out of range, or mid-grapheme), or
  ///   when the proportional split would leave either half below the minimum caption duration.
  @discardableResult
  func splitCaption(_ caption: DesignBlockID, at cursorOffset: Int) -> DesignBlockID? {
    guard let engine, engine.block.isValid(caption) else { return nil }
    let text = (try? engine.block.getString(caption, property: Constants.textProperty)) ?? ""
    guard let texts = Self.splitTexts(text, at: cursorOffset) else { return nil }
    let duration = (try? engine.block.getDuration(caption)) ?? 0
    let leftDuration = duration * Double(texts.left.utf16.count) / Double(text.utf16.count)
    return splitCaption(caption, into: texts, leftDuration: leftDuration)
  }

  /// Splits a caption where the playhead sits — what web does when the split comes from the timeline.
  /// Splitting purely on time (as the generic clip split does) would leave both halves holding the whole
  /// line, so the text is divided too, at the word gap nearest the playhead.
  ///
  /// The playhead — not the snapped character count — sets the duration, so the clip edge lands exactly
  /// where the user aimed instead of moving by however far the snap travelled.
  ///
  /// No-op when the playhead is outside the caption, so close to an edge that one side would be empty, or
  /// close enough that either side would fall below the minimum caption duration.
  /// One undo step.
  /// - Returns: The new caption holding the tail, or `nil` if nothing was split.
  @discardableResult
  func splitCaption(_ caption: DesignBlockID, atTime playheadSeconds: Double) -> DesignBlockID? {
    guard let engine, engine.block.isValid(caption) else { return nil }
    let start = (try? engine.block.getTimeOffset(caption)) ?? 0
    let duration = (try? engine.block.getDuration(caption)) ?? 0
    guard duration > 0, playheadSeconds > start, playheadSeconds < start + duration else { return nil }

    let text = (try? engine.block.getString(caption, property: Constants.textProperty)) ?? ""
    let played = (playheadSeconds - start) / duration
    let proportional = Int((Double(text.utf16.count) * played).rounded())
    // Only this time-derived split snaps to a word gap; a caret split stays where the user put it.
    let offset = Self.wordBoundary(in: text, nearestTo: proportional)
    guard let texts = Self.splitTexts(text, at: offset) else { return nil }
    return splitCaption(caption, into: texts, leftDuration: playheadSeconds - start)
  }

  /// The half both splits share. The tail takes the remainder, so the pair tiles exactly the range the
  /// original occupied with no float drift.
  private func splitCaption(
    _ caption: DesignBlockID,
    into texts: (left: String, right: String),
    leftDuration: Double,
  ) -> DesignBlockID? {
    guard let engine, let track = existingCaptionTrack() else { return nil }
    var createdCaption: DesignBlockID?
    // Captured for the rollback path, which has to restore the original if it was already shortened.
    let originalText = (try? engine.block.getString(caption, property: Constants.textProperty)) ?? ""
    let originalDuration = (try? engine.block.getDuration(caption)) ?? 0
    do {
      let siblings = try captionChildren(engine, of: track)
      guard let index = siblings.firstIndex(of: caption) else { return nil }

      let offset = (try? engine.block.getTimeOffset(caption)) ?? 0
      let rightDuration = originalDuration - leftDuration

      // Both halves have to clear the caption floor, and this is the only place that holds for every
      // split: the timeline button greys itself out, but the caret has no such affordance, so cutting a
      // character from either end would leave a caption too short to read or to grab. Rejecting rather
      // than clamping keeps the pair tiling exactly the range the original occupied.
      let minimum = interactor.timelineProperties.configuration.minDuration(for: .caption).seconds
      guard leftDuration >= minimum, rightDuration >= minimum else { return nil }

      // Duplicating copies the style and animations, so the tail needs no preset apply.
      let new = try engine.block.duplicate(caption, attachToParent: false)
      createdCaption = new

      // Retimed while still detached: attaching first would put two captions on the same range, and the
      // track ripples whatever overlaps forward, shoving every following caption out of place.
      try engine.block.setString(new, property: Constants.textProperty, value: texts.right)
      try engine.block.setTimeOffset(new, offset: offset + leftDuration)
      try engine.block.setDuration(new, duration: rightDuration)
      try engine.block.setString(caption, property: Constants.textProperty, value: texts.left)
      try engine.block.setDuration(caption, duration: leftDuration)

      // Only now, with a gap the right size waiting for it, does the tail join the track.
      try engine.block.insertChild(into: track, child: new, at: index + 1)

      interactor.addUndoStep()
      return new
    } catch {
      // Restore the original too: the writes above may already have truncated it.
      if let createdCaption, engine.block.isValid(createdCaption) {
        try? engine.block.destroy(createdCaption)
      }
      if engine.block.isValid(caption) {
        try? engine.block.setString(caption, property: Constants.textProperty, value: originalText)
        try? engine.block.setDuration(caption, duration: originalDuration)
      }
      interactor.handleError(error)
      return nil
    }
  }

  /// The text either side of a UTF-16 offset, or `nil` when the offset doesn't divide the text in two — at
  /// either end, out of range, or mid-grapheme, where `samePosition` rejects the cut (e.g. mid-emoji).
  private static func splitTexts(_ text: String, at cursorOffset: Int) -> (left: String, right: String)? {
    let utf16 = text.utf16
    guard cursorOffset >= 0,
          let utf16Index = utf16.index(utf16.startIndex, offsetBy: cursorOffset, limitedBy: utf16.endIndex),
          let splitIndex = utf16Index.samePosition(in: text) else { return nil }
    let left = String(text[..<splitIndex])
    let right = String(text[splitIndex...])
    guard !left.isEmpty, !right.isEmpty else { return nil }
    return (left, right)
  }

  /// The offset of the word gap closest to `target`, searching outwards in both directions. Falls back to
  /// `target` for text with no gaps at all (a single long word), where any cut is arbitrary anyway.
  private static func wordBoundary(in text: String, nearestTo target: Int) -> Int {
    let units = Array(text.utf16)
    guard !units.isEmpty else { return target }
    let isGap: (Int) -> Bool = { index in
      guard index > 0, index < units.count else { return false }
      // A break belongs *after* the space, so the trailing caption doesn't start with one.
      return units[index - 1] == 32
    }
    if isGap(target) {
      return target
    }
    for distance in 1 ... units.count {
      if isGap(target - distance) {
        return target - distance
      }
      if isGap(target + distance) {
        return target + distance
      }
    }
    return target
  }

  // MARK: - Import (SRT/VTT)

  /// Imports an SRT or VTT file's captions, replacing any existing caption track, as one undo step.
  ///
  /// Cues are appended to a *detached* track and attached to the page once — appending to an attached track
  /// re-runs the engine's style sync each time. Errors are rethrown for the sheet's import-specific alerts.
  func importCaptions(from url: URL) async throws {
    guard let engine, let page = currentPage() else { return }
    let captions = try await engine.block.createCaptionsFromURI(url)
    let previousTrack = existingCaptionTrack()
    var newTrack: DesignBlockID?
    do {
      let track = try engine.block.create(.captionTrack)
      newTrack = track
      for caption in captions {
        try engine.block.appendChild(to: track, child: caption)
      }
      try engine.block.appendChild(to: page, child: track) // attach before styling

      if let first = captions.first {
        await applyDefaultStyling(engine, to: first)
        // Unconditional, unlike `createCaption()`: this track is brand new, so there is never an existing
        // placement to keep.
        try centerCaption(engine, first)
        // The playhead stays put: import (and the generate flow reusing it) must not jump to the first cue.
      }

      // Destroy the old track last, so a failure above leaves the existing captions untouched.
      if let previousTrack, engine.block.isValid(previousTrack) {
        try engine.block.destroy(previousTrack)
      }

      interactor.addUndoStep()
    } catch {
      if let newTrack, engine.block.isValid(newTrack) {
        try? engine.block.destroy(newTrack)
      }
      for caption in captions where engine.block.isValid(caption) {
        try? engine.block.destroy(caption)
      }
      throw error
    }
  }

  /// Reverts the most recent committed step — used to undo an already-committed import when generation is
  /// cancelled while the (non-cancellable) import is running, so cancellation leaves the scene untouched.
  func revertLastStep() {
    guard let engine, (try? engine.editor.canUndo()) == true else { return }
    try? engine.editor.undo()
  }

  /// Deletes every caption by destroying the caption track, returning the sheet to its empty state. One
  /// undo step.
  func deleteAllCaptions() {
    guard let engine, let track = existingCaptionTrack() else { return }
    do {
      try engine.block.destroy(track)
      interactor.addUndoStep()
    } catch {
      interactor.handleError(error)
    }
  }

  // MARK: - Styling (inspector "Style" preset grid)

  /// Applies a style preset to the selected caption; the engine fans it out to every caption in the track.
  /// Records the applied preset id on the track for the grid highlight. One undo step.
  ///
  /// Re-styling changes the *look* only: a caption the user pinched keeps that size and its placement, with
  /// the preset's typography scaled to match. A deliberate divergence from web, which applies the preset
  /// bare and resets the box — but a mobile caption is placed by hand, so re-placing it every restyle is
  /// busywork.
  func applyStylePreset(sourceID: String, assetResult: AssetResult, to caption: DesignBlockID) async {
    guard let engine, engine.block.isValid(caption) else { return }
    do {
      let keptTrackBox = try await applyPreservingSize(
        engine,
        sourceID: sourceID,
        assetResult: assetResult,
        to: caption,
      )
      if !keptTrackBox {
        // The preset's box stands, hanging off the caption's old top-left, so re-center it the way
        // `createCaption()` centers a caption it has just styled.
        try centerCaption(engine, caption)
      }
      stampAppliedPreset(engine, on: caption, assetID: assetResult.id)
      interactor.addUndoStep()
    } catch {
      interactor.handleError(error)
    }
  }

  /// Applies a preset to ONE caption — the engine fans the style out to the siblings — keeping the box the
  /// track already has. Every caption preset declares its own `width`/`height`, and those are *synced*
  /// properties, so a bare apply re-frames the whole track and throws away a size the user pinched.
  ///
  /// The one place that sequence lives, shared by every caller: a preset tap, a new caption, an import.
  /// - Returns: `true` when the track's box was kept, `false` when the preset's own box stands — the only
  ///   case in which the caller still has to place the caption.
  private func applyPreservingSize(
    _ engine: Engine,
    sourceID: String,
    assetResult: AssetResult,
    to caption: DesignBlockID,
  ) async throws -> Bool {
    let widthBeforePreset = captionWidth(engine, of: caption)
    let heightBeforePreset = captionHeight(engine, of: caption)
    try await engine.asset.applyToBlock(sourceID: sourceID, assetResult: assetResult, block: caption)
    guard let ratio = sizeRestoreRatio(engine, of: caption, to: widthBeforePreset) else { return false }
    restoreCaptionBox(engine, of: caption, by: ratio, height: heightBeforePreset)
    return true
  }

  /// Centers a caption on its page. Aligning a *single* block registers an outgoing position sync, so this
  /// re-places every caption on the track — which is why it may only run when there is no placement to keep.
  private func centerCaption(_ engine: Engine, _ caption: DesignBlockID) throws {
    try engine.block.alignHorizontally([caption], alignment: .center)
    try engine.block.alignVertically([caption], alignment: .center)
  }

  /// The asset id of the last applied caption style preset, read from the caption track, or `nil` if none
  /// was recorded. Drives the grid's selection highlight.
  func appliedPresetIdentifier() -> String? {
    guard let engine, let track = existingCaptionTrack() else { return nil }
    guard (try? engine.block.hasMetadata(track, key: Constants.appliedPresetMetadataKey)) == true,
          let stamp = try? engine.block.getMetadata(track, key: Constants.appliedPresetMetadataKey) else { return nil }
    // Scenes stamped before the id collapsed to the asset id carry a `sourceID|assetID` pair.
    return stamp.split(separator: "|").last.map(String.init)
  }

  /// Records the applied preset id on the caption's parent track. Uses the parent (not the page's first
  /// track) so it targets the right track mid-import, while an old track is being replaced.
  private func stampAppliedPreset(_ engine: Engine, on caption: DesignBlockID, assetID: String) {
    guard let track = try? engine.block.getParent(caption), engine.block.isValid(track) else { return }
    try? engine.block.setMetadata(track, key: Constants.appliedPresetMetadataKey, value: assetID)
  }

  /// A caption's width as the engine stores it. `nil` for an auto-sized caption, which has no box of its own
  /// and should simply take the preset's.
  private func captionWidth(_ engine: Engine, of caption: DesignBlockID) -> LayoutLength? {
    guard let mode = try? engine.block.getWidthMode(caption), mode != .auto,
          let value = try? engine.block.getWidth(caption) else { return nil }
    return (value, mode)
  }

  /// A caption's height, read the same way as ``captionWidth(_:of:)``.
  private func captionHeight(_ engine: Engine, of caption: DesignBlockID) -> LayoutLength? {
    guard let mode = try? engine.block.getHeightMode(caption), mode != .auto,
          let value = try? engine.block.getHeight(caption) else { return nil }
    return (value, mode)
  }

  /// How much the caption has to be scaled to get back the size it had before the preset re-framed it, or
  /// `nil` when there is nothing to restore.
  ///
  /// Width alone drives it: the scale it feeds is uniform and the width is the axis the typography follows.
  /// Requiring both sides in the same mode keeps the units cancelling, so the ratio needs no layout pass.
  private func sizeRestoreRatio(
    _ engine: Engine,
    of caption: DesignBlockID,
    to previous: LayoutLength?,
  ) -> Float? {
    guard let previous, let current = captionWidth(engine, of: caption),
          current.mode == previous.mode else { return nil }
    let ratio = previous.value / current.value
    // A zero or non-finite width would collapse the caption or trip an engine assert; keep the preset's box.
    guard ratio.isFinite, ratio > 0 else { return nil }
    return ratio
  }

  /// Puts every caption in the track back on the box the user gave them, scaling each around its own
  /// top-left corner — so the size and the placement both survive, exactly as a pinch leaves them.
  ///
  /// Looping the *scale* does not break the "never loop a style setter" rule:
  /// ``IMGLYEngine/BlockAPI/scale(_:to:anchorX:anchorY:)`` writes values directly rather than through a
  /// synced property, so it never reaches the siblings on its own.
  ///
  /// The scale is uniform (that is what carries the typography), so it is driven by the width ratio alone
  /// and the height is written back once afterwards — otherwise a caption dragged wider but not taller
  /// comes out stretched by the width's factor. Once is enough: the outgoing sync re-runs the height setter
  /// on each sibling. It must follow every scale, though — `scale` flushes the pending syncs before it
  /// runs, so a height written inside the loop lands on siblings that are not scaled yet.
  private func restoreCaptionBox(
    _ engine: Engine,
    of caption: DesignBlockID,
    by ratio: Float,
    height: LayoutLength?,
  ) {
    // The preset reproduced the caption's size, so a default-sized caption is left exactly as a bare apply
    // leaves it instead of having its box and position rewritten as a side effect.
    guard abs(ratio - 1) > Constants.sizeRestoreEpsilon else { return }
    for target in captionsInTrack(engine, of: caption) where engine.block.isValid(target) {
      // Top-left anchor: the position is left untouched, so there is no placement to capture and restore.
      try? engine.block.scale(target, to: ratio, anchorX: 0, anchorY: 0)
    }
    guard let height, engine.block.isValid(caption) else { return }
    // Mode before value: the mode setter only swaps the unit, it does not convert the value.
    try? engine.block.setHeightMode(caption, mode: height.mode)
    try? engine.block.setHeight(caption, value: height.value)
  }

  /// Every caption in the track holding `caption`, falling back to the caption alone when it has no track.
  private func captionsInTrack(_ engine: Engine, of caption: DesignBlockID) -> [DesignBlockID] {
    let track = try? engine.block.getParent(caption)
    return track.flatMap { try? captionChildren(engine, of: $0) } ?? [caption]
  }

  // MARK: - Private helpers

  /// How long a caption inserted at `start` may be: the gap up to the next caption, capped at the default
  /// length and floored at the timeline's minimum.
  ///
  /// Fitting the gap is what keeps the rest of the track still — the caption track preserves gaps but
  /// ripples anything that *overlaps* forward, so a fixed three seconds dropped between two generated cues
  /// would shove every later caption past the end of the video.
  private static func insertedDuration(startingAt start: Double, before nextStart: Double?) -> Double {
    guard let nextStart, nextStart > start else { return Constants.defaultCaptionDuration }
    return max(Constants.minimumCaptionDuration, min(Constants.defaultCaptionDuration, nextStart - start))
  }

  /// A blank copy of a caption, detached and timed to start at `offset` and run for `duration` — ready to
  /// be attached wherever the caller wants it.
  ///
  /// Copying, rather than creating and styling a caption, is what keeps the rest of the track still.
  /// Attaching a block seeds its *synced* properties one at a time, in name order — so a rotated caption has
  /// its rotation replayed while its width is still the newcomer's default, and the position the engine
  /// compensates for that rotation is computed against a half-built box. The error lands on the new caption
  /// and, through the position sync, on every sibling; it compounds with each caption added. A copy already
  /// agrees with its siblings on every synced property, so the seeding writes nothing and there is nothing
  /// to compensate. It also carries the style and the animations across, which no property sync does.
  ///
  /// Retimed while still detached: attaching first would put two captions on the same range, and the track
  /// ripples whatever overlaps forward.
  private func detachedCopy(
    _ engine: Engine,
    of caption: DesignBlockID,
    at offset: Double,
    duration: Double = Constants.defaultCaptionDuration,
  ) throws -> DesignBlockID {
    let copy = try engine.block.duplicate(caption, attachToParent: false)
    do {
      try engine.block.setString(copy, property: Constants.textProperty, value: "")
      try engine.block.setTimeOffset(copy, offset: offset)
      try engine.block.setDuration(copy, duration: duration)
    } catch {
      // Nothing else knows about the copy yet, so it has to be cleaned up here or it leaks detached.
      try? engine.block.destroy(copy)
      throw error
    }
    return copy
  }

  private func captionChildren(_ engine: Engine, of track: DesignBlockID) throws -> [DesignBlockID] {
    try engine.block.getChildren(track).filter { engine.block.isValid($0) && isCaption($0) }
  }

  private func currentPage() -> DesignBlockID? {
    interactor.timelineProperties.currentPage
  }

  private func isCaption(_ block: DesignBlockID) -> Bool {
    guard let engine else { return false }
    return (try? engine.block.getType(block)) == DesignBlockType.caption.rawValue
  }

  /// The single caption track on the current page, if one exists.
  private func existingCaptionTrack() -> DesignBlockID? {
    guard let engine, let page = currentPage() else { return nil }
    let children = (try? engine.block.getChildren(page)) ?? []
    return children.first {
      engine.block.isValid($0) && (try? engine.block.getType($0)) == DesignBlockType.captionTrack.rawValue
    }
  }

  /// Applies the default `outline` preset to a track's *first* caption — every later one is a copy of its
  /// predecessor and needs no styling. A missing preset source must not break creation, so the caption is
  /// kept (unstyled) rather than failing.
  ///
  /// Deliberately a *bare* apply, unlike ``applyStylePreset(sourceID:assetResult:to:)``: this is the caption's
  /// first styling, so the box it currently has is an engine default, not a size the user chose. Preserving it
  /// would pin the caption to that default forever — and the two creation paths do not even agree on what it
  /// is. `engine.block.create(.caption)` sizes a caption 100x100 *absolute*, whereas a caption from
  /// `createCaptionsFromURI` carries no size at all and the layout pass fills in 100% x 100% — the whole page.
  /// Restoring *that* cancels the preset's 80% x 20% out to a full-page caption, which is what the preset
  /// exists to set. There is nothing to preserve here; let the preset's box stand.
  private func applyDefaultStyling(_ engine: Engine, to caption: DesignBlockID) async {
    guard engine.asset.findAllSources().contains(Constants.presetsSourceID) else { return }
    do {
      guard let preset = try await engine.asset.fetchAsset(
        sourceID: Constants.presetsSourceID,
        assetID: Constants.defaultPresetID,
      ) else { return }
      try await engine.asset.applyToBlock(
        sourceID: Constants.presetsSourceID,
        assetResult: preset,
        block: caption,
      )
      stampAppliedPreset(engine, on: caption, assetID: Constants.defaultPresetID)
    } catch {
      // Preset unavailable: keep the caption rather than failing creation.
    }
  }
}
