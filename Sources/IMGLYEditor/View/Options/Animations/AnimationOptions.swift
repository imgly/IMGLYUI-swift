@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

struct AnimationOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @State private var selectedTab: AnimationTab = .in
  @State private var sheetState: EffectSheetState = .selection
  @State private var captionApplies = CaptionApplyQueue()

  private static let animationsSourceID = "ly.img.animations"

  private func animationGetter(for tab: AnimationTab) -> Interactor.RawGetter<AssetSelection> {
    { engine, block in
      guard let animationBlock = try? Self.getAnimation(on: block, tab: tab, engine: engine),
            engine.block.isValid(animationBlock) else {
        return AssetSelection()
      }
      let type = try engine.block.getType(animationBlock)
      if type.hasSuffix("/none") {
        return AssetSelection()
      }
      let animationType = type.components(separatedBy: "/").last
      return AssetSelection(identifier: animationType, id: animationBlock)
    }
  }

  private func animationSetter(for tab: AnimationTab) -> Interactor.RawSetter<AssetSelection> {
    { engine, blocks, value, completion in
      if let caption = blocks.first, blocks.count == 1, Self.isCaption(caption, engine: engine) {
        applyToCaptionTrack(value, caption: caption, tab: tab, engine: engine, completion: completion)
        return false
      }
      var didChange = false
      try blocks.forEach { block in
        if let identifier = value.identifier,
           let animationType = AnimationType(rawValue: "//ly.img.ubq/animation/\(identifier)") {
          didChange = try Self.applyAnimation(animationType, to: block, tab: tab, engine: engine) || didChange
          if tab != .loop {
            let type = try engine.block.getType(try Self.getAnimation(on: block, tab: tab, engine: engine))
            if !type.hasSuffix("/none") {
              let outgoing = tab == .out ? block : previousTransitionSibling(engine: engine, clip: block)
              if let outgoing, hasRealTransition(engine: engine, outgoing: outgoing) {
                let transition = try engine.block.getTransition(outgoing)
                try engine.block.destroy(transition)
              }
            }
          }
        } else {
          didChange = try Self.clearAnimation(on: block, tab: tab, engine: engine) || didChange
        }
      }
      if didChange,
         value.identifier != nil,
         let pageID = interactor.timelineProperties.currentPage {
        for block in blocks {
          interactor.timelineProperties.timeline?.animationPreview.playAnimation(
            engine: engine,
            pageID: pageID,
            clip: block,
            mode: Self.previewMode(for: tab),
          )
        }
      }
      return try (completion?(engine, blocks, didChange) ?? false) || didChange
    }
  }

  private static func isCaption(_ block: DesignBlockID, engine: Engine) -> Bool {
    (try? engine.block.getType(block)) == DesignBlockType.caption.rawValue
  }

  /// The animation library applies a caption's animation to every caption on its track, so a caption goes through
  /// it instead of `setInAnimation`, which would animate that one caption only.
  private func applyToCaptionTrack(
    _ value: AssetSelection,
    caption: DesignBlockID,
    tab: AnimationTab,
    engine: Engine,
    completion: Interactor.PropertyCompletion?,
  ) {
    let type = value.identifier ?? "none"
    let asset = AssetResult(
      id: "\(tab.group)/\(type)",
      meta: ["mode": tab.group, "type": type],
      context: .init(sourceID: Self.animationsSourceID),
    )
    captionApplies.enqueue {
      do {
        // "None" has nothing to clear while the caption has no animation, as on the web.
        if value.identifier == nil, !hasAnimation(for: tab, on: caption) {
          return
        }
        try await engine.asset.applyToBlock(sourceID: Self.animationsSourceID, assetResult: asset, block: caption)
        _ = try completion?(engine, [caption], true)
        if value.identifier != nil, let pageID = interactor.timelineProperties.currentPage {
          interactor.timelineProperties.timeline?.animationPreview.playAnimation(
            engine: engine,
            pageID: pageID,
            clip: caption,
            mode: Self.previewMode(for: tab),
          )
        }
      } catch {
        interactor.handleError(error)
      }
    }
  }

  private static func previewMode(for tab: AnimationTab) -> AnimationPreview.Mode {
    switch tab {
    case .in: .in
    case .out: .out
    case .loop: .loop
    }
  }

  private static func applyAnimation(
    _ animationType: AnimationType,
    to block: DesignBlockID,
    tab: AnimationTab,
    engine: Engine,
  ) throws -> Bool {
    let animation = try engine.block.createAnimation(animationType)
    do {
      try setAnimation(animation, on: block, tab: tab, engine: engine)
      return true
    } catch {
      try? engine.block.destroy(animation)
      throw error
    }
  }

  private static func clearAnimation(
    on block: DesignBlockID,
    tab: AnimationTab,
    engine: Engine,
  ) throws -> Bool {
    guard let existingAnimation = try? getAnimation(on: block, tab: tab, engine: engine),
          engine.block.isValid(existingAnimation) else { return false }
    let type = try? engine.block.getType(existingAnimation)
    guard type.map({ !$0.hasSuffix("/none") }) ?? false else { return false }
    try engine.block.destroy(existingAnimation)
    return true
  }

  private static func setAnimation(
    _ animation: DesignBlockID,
    on block: DesignBlockID,
    tab: AnimationTab,
    engine: Engine,
  ) throws {
    switch tab {
    case .in: try engine.block.setInAnimation(block, animation: animation)
    case .loop: try engine.block.setLoopAnimation(block, animation: animation)
    case .out: try engine.block.setOutAnimation(block, animation: animation)
    }
  }

  private static func getAnimation(
    on block: DesignBlockID,
    tab: AnimationTab,
    engine: Engine,
  ) throws -> DesignBlockID {
    switch tab {
    case .in: try engine.block.getInAnimation(block)
    case .loop: try engine.block.getLoopAnimation(block)
    case .out: try engine.block.getOutAnimation(block)
    }
  }

  private func hasAnimation(for tab: AnimationTab) -> Bool {
    guard let id else { return false }
    return hasAnimation(for: tab, on: id)
  }

  private func hasAnimation(for tab: AnimationTab, on block: DesignBlockID) -> Bool {
    guard let engine = interactor.engine else { return false }
    guard let animationBlock = try? Self.getAnimation(on: block, tab: tab, engine: engine),
          engine.block.isValid(animationBlock) else { return false }
    let type = try? engine.block.getType(animationBlock)
    return type.map { !$0.hasSuffix("/none") } ?? false
  }

  private func thumbnailsBaseURL(for block: DesignBlockID?) -> URL? {
    guard let block, let engine = interactor.engine else { return nil }
    // Captions render as text, so they use the text animation thumbnails.
    let type = try? engine.block.getType(block)
    let isText = type == DesignBlockType.text.rawValue || type == DesignBlockType.caption.rawValue
    let sourceName = isText ? "ly.img.animation.text" : "ly.img.animation"
    guard let basePath = try? engine.editor.getSettingString("basePath"),
          let base = URL(string: basePath) else { return nil }
    return base.appendingPathComponent(sourceName).appendingPathComponent("thumbnails")
  }

  private func previewAnimationAfterPropertyChange() {
    guard sheetState.isProperties,
          let engine = interactor.engine,
          let id,
          let pageID = interactor.timelineProperties.currentPage else { return }
    interactor.timelineProperties.timeline?.animationPreview.playAnimation(
      engine: engine,
      pageID: pageID,
      clip: id,
      mode: Self.previewMode(for: selectedTab),
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      let selection = interactor.bind(
        id,
        getter: animationGetter(for: selectedTab),
        setter: animationSetter(for: selectedTab),
      )
      let baseURL = thumbnailsBaseURL(for: id)

      EffectOptions(
        selection: selection,
        item: { asset, sheetBinding in
          if asset.result.meta?["type"] == "none" {
            EmptyView()
          } else {
            AnimationItem(
              asset: asset,
              selection: selection,
              sheetState: sheetBinding,
              thumbnailsBaseURL: baseURL,
            )
          }
        },
        identifier: { $0.result.meta?["type"] },
        sources: [.init(
          id: Self.animationsSourceID,
          config: .init(groups: [selectedTab.group]),
        )],
        sheetState: $sheetState,
      )
      .id(selectedTab)
      .onChange(of: selection.wrappedValue?.identifier) { (_: String?) in
        if case let .properties(asset) = sheetState {
          sheetState = .selection
          interactor.sheet.commit { model in
            model.style = asset.previousStyle
          }
        }
      }

      if !sheetState.isProperties {
        AnimationTabBar(
          selectedTab: $selectedTab,
          hasAnimation: hasAnimation,
        )
      }
    }
    // Android emits an animation preview after a properties-sheet change finishes. Asset-backed
    // controls publish their commit through the engine history signal, so replay once that step lands.
    .onChange(of: interactor.historyVersion) { _ in
      previewAnimationAfterPropertyChange()
    }
  }
}

@MainActor
private func previousTransitionSibling(engine: Engine, clip: DesignBlockID) -> DesignBlockID? {
  let children = transitionTrackChildren(engine: engine, clip: clip)
  guard let index = children.firstIndex(of: clip), index > 0 else { return nil }
  return children[index - 1]
}

/// Runs caption animation applies one after another, so quick taps land in tap order. A reference type, so enqueuing
/// does not redraw the view.
@MainActor
private final class CaptionApplyQueue {
  private var last: Task<Void, Never>?

  func enqueue(_ operation: @escaping @MainActor () async -> Void) {
    let previous = last
    last = Task {
      await previous?.value
      await operation()
    }
  }
}
