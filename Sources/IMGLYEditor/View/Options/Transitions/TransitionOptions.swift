@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

struct TransitionOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var outgoingID

  @State private var sheetState: EffectSheetState = .selection
  @State private var hasTransitionsInTrack = false

  private static let sourceID = "ly.img.transitions"

  private func getter(engine: Engine, block: DesignBlockID) -> AssetSelection {
    guard let transition = try? engine.block.getTransition(block), engine.block.isValid(transition),
          let type = try? engine.block.getType(transition) else {
      return AssetSelection()
    }
    return AssetSelection(identifier: type.components(separatedBy: "/").last, id: transition)
  }

  private func setter(engine: Engine, block: DesignBlockID, value: AssetSelection) throws -> Bool {
    let existing = try engine.block.getTransition(block)
    guard let identifier = value.identifier else {
      guard engine.block.isValid(existing) else { return false }
      try engine.block.destroy(existing)
      return true
    }
    guard let type = TransitionType(rawValue: "//ly.img.ubq/transition/\(identifier)") else { return false }
    let transition = try engine.block.createTransition(type)
    do {
      if engine.block.isValid(existing) {
        try engine.block.destroy(existing)
      }
      try engine.block.setTransition(block, transition: transition)
      try clearConflictingAnimations(engine: engine, outgoing: block)
      return true
    } catch {
      try? engine.block.destroy(transition)
      throw error
    }
  }

  private func thumbnailsBaseURL() -> URL? {
    guard let engine = interactor.engine,
          let basePath = try? engine.editor.getSettingString("basePath"),
          let baseURL = URL(string: basePath) else { return nil }
    return baseURL.appendingPathComponent(Self.sourceID).appendingPathComponent("thumbnails")
  }

  var body: some View {
    let selection = interactor.bind(
      outgoingID,
      getter: { engine, block in getter(engine: engine, block: block) },
      setter: { engine, blocks, value, _ in
        var changed = false
        for block in blocks {
          changed = try setter(engine: engine, block: block, value: value) || changed
        }
        if changed {
          try engine.editor.addUndoStep()
          if let pageID = interactor.timelineProperties.currentPage,
             let outgoingID {
            interactor.timelineProperties.timeline?.animationPreview.playTransition(
              engine: engine,
              pageID: pageID,
              outgoing: outgoingID,
            )
          }
        }
        return changed
      },
      completion: nil,
    )

    VStack(spacing: 0) {
      EffectOptions(
        selection: selection,
        item: { asset, state in
          if asset.result.meta?["type"] == "none" {
            EmptyView()
          } else {
            TransitionItem(
              asset: asset,
              selection: selection,
              sheetState: state,
              thumbnailsBaseURL: thumbnailsBaseURL(),
            )
          }
        },
        identifier: { $0.result.meta?["type"] },
        sources: [.init(id: Self.sourceID)],
        sheetState: $sheetState,
      )
      if case .selection = sheetState {
        if let outgoingID, selection.wrappedValue?.identifier != nil {
          Button {
            applyToTrack(outgoing: outgoingID)
          } label: {
            Text(String(localized: .imgly
                .localized("ly_img_editor_sheet_transition_button_apply_to_all_clips_in_track")))
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 16)
        } else if hasTransitionsInTrack, let outgoingID {
          Button(role: .destructive) {
            removeFromTrack(outgoing: outgoingID)
          } label: {
            Text(String(localized: .imgly
                .localized("ly_img_editor_sheet_transition_button_remove_all_transitions_in_track")))
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .tint(.red)
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 16)
        }
      }
    }
    .background(Color(.systemGroupedBackground))
    .onAppear {
      refreshTrackAction()
    }
    .onChange(of: outgoingID) { _ in
      refreshTrackAction()
    }
    .onChange(of: selection.wrappedValue?.identifier) { _ in
      refreshTrackAction()
      if case let .properties(asset) = sheetState {
        sheetState = .selection
        interactor.sheet.commit { $0.style = asset.previousStyle }
      }
    }
    // Android emits a transition preview after a properties-sheet change finishes. Asset-backed
    // controls publish their commit through the engine history signal, so replay once that step lands.
    .onChange(of: interactor.historyVersion) { _ in
      previewTransitionAfterPropertyChange()
    }
  }

  private func refreshTrackAction() {
    guard let engine = interactor.engine, let outgoingID else { return }
    hasTransitionsInTrack = trackHasRealTransition(engine: engine, outgoing: outgoingID)
    updateSheetHeight()
  }

  private func updateSheetHeight() {
    guard case .selection = sheetState else { return }
    let hasSelectedTransition = outgoingID.flatMap { id in
      interactor.engine.map { getter(engine: $0, block: id).identifier != nil }
    } ?? false
    let detent: PresentationDetent = hasSelectedTransition || hasTransitionsInTrack
      ? .imgly.small
      : .imgly.tiny
    guard interactor.sheet.style.detent != detent else { return }
    interactor.sheet.commit { $0.style = .only(detent: detent) }
  }

  private func previewTransitionAfterPropertyChange() {
    guard sheetState.isProperties,
          let engine = interactor.engine,
          let outgoingID,
          let pageID = interactor.timelineProperties.currentPage else { return }
    interactor.timelineProperties.timeline?.animationPreview.playTransition(
      engine: engine,
      pageID: pageID,
      outgoing: outgoingID,
    )
  }

  private func applyToTrack(outgoing: DesignBlockID) {
    guard let engine = interactor.engine,
          let active = try? engine.block.getTransition(outgoing), engine.block.isValid(active) else { return }
    do {
      for candidate in transitionTrackChildren(engine: engine, clip: outgoing) where candidate != outgoing {
        let existing = try engine.block.getTransition(candidate)
        guard let incoming = transitionIncomingClip(engine: engine, outgoing: candidate) else { continue }
        let duplicate = try engine.block.duplicate(active, attachToParent: false)
        let maximumDuration = min(
          try engine.block.getDuration(candidate) / 2,
          try engine.block.getDuration(incoming) / 2,
        )
        try engine.block.setDuration(
          duplicate,
          duration: min(try engine.block.getDuration(duplicate), maximumDuration),
        )
        try engine.block.setTransition(candidate, transition: duplicate)
        if engine.block.isValid(existing) {
          try engine.block.destroy(existing)
        }
        try clearConflictingAnimations(engine: engine, outgoing: candidate)
      }
      try engine.editor.addUndoStep()
      interactor.refreshTimelineAfterHistoryChange()
      refreshTrackAction()
    } catch { interactor.handleError(error) }
  }

  private func removeFromTrack(outgoing: DesignBlockID) {
    guard let engine = interactor.engine else { return }
    do {
      for clip in transitionTrackChildren(engine: engine, clip: outgoing)
        where (try? engine.block.supportsTransition(clip)) == true {
        let transition = try engine.block.getTransition(clip)
        if engine.block.isValid(transition) {
          try engine.block.destroy(transition)
        }
      }
      try engine.editor.addUndoStep()
      interactor.refreshTimelineAfterHistoryChange()
      refreshTrackAction()
    } catch { interactor.handleError(error) }
  }
}

private struct TransitionItem: View {
  let asset: AssetLoader.Asset
  @Binding var selection: AssetSelection?
  @Binding var sheetState: EffectSheetState
  let thumbnailsBaseURL: URL?

  private var identifier: String? {
    asset.result.meta?["type"]
  }

  private var selected: Bool {
    selection?.identifier == identifier
  }

  private var thumbnailURL: URL? {
    guard let baseURL = thumbnailsBaseURL else { return nil }
    let slug = asset.result.id.components(separatedBy: ".").last ?? ""
    return baseURL.appendingPathComponent("\(slug).png")
  }

  private var title: String {
    let fallback = asset.result.label ?? ""
    let slug = asset.result.id.components(separatedBy: ".").last ?? ""
    guard !slug.isEmpty else { return fallback }
    let key = "ly_img_editor_asset_label_\(slug.replacingOccurrences(of: "-", with: "_"))"
    let resolved = String(localized: .imgly.localized(String.LocalizationValue(key)))
    return resolved == key ? fallback : resolved
  }

  private var properties: [EffectProperty] {
    guard let properties = asset.result.payload?.properties, let id = selection?.id else { return [] }
    return TransitionPropertyDefinitions.properties(
      from: properties,
      sourceID: asset.sourceID,
      assetResult: asset.result,
      transitionBlockID: id,
    )
  }

  var body: some View {
    SelectableAssetItem(content: {
      ReloadableAsyncImage(url: thumbnailURL, accessibilityLabel: title) { image in
        image.resizable().aspectRatio(contentMode: .fill).clipped().aspectRatio(1, contentMode: .fit).cornerRadius(8)
      } onTap: {
        selection = AssetSelection(
          identifier: identifier,
          assetURL: asset.result.url?.absoluteString,
          sourceID: asset.sourceID,
        )
      }
    }, title: title, selected: selected, properties: properties, asset: asset, sheetState: $sheetState)
  }
}
