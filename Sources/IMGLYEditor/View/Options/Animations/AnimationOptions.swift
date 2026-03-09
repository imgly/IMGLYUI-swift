@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

struct AnimationOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @State private var selectedTab: AnimationTab = .in
  @State private var sheetState: EffectSheetState = .selection

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
      var didChange = false
      try blocks.forEach { block in
        if let identifier = value.identifier,
           let animationType = AnimationType(rawValue: "//ly.img.ubq/animation/\(identifier)") {
          didChange = try Self.applyAnimation(animationType, to: block, tab: tab, engine: engine) || didChange
        } else {
          didChange = try Self.clearAnimation(on: block, tab: tab, engine: engine) || didChange
        }
      }
      return try (completion?(engine, blocks, didChange) ?? false) || didChange
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
    guard let id, let engine = interactor.engine else { return false }
    guard let animationBlock = try? Self.getAnimation(on: id, tab: tab, engine: engine),
          engine.block.isValid(animationBlock) else { return false }
    let type = try? engine.block.getType(animationBlock)
    return type.map { !$0.hasSuffix("/none") } ?? false
  }

  private func thumbnailsBaseURL(for block: DesignBlockID?) -> URL? {
    guard let block, let engine = interactor.engine else { return nil }
    let isText = (try? engine.block.getType(block)) == DesignBlockType.text.rawValue
    let sourceName = isText ? "ly.img.animation.text" : "ly.img.animation"
    let base = engine.defaultAssetSourcesBaseURL ?? Engine.assetBaseURL
    return base.appendingPathComponent(sourceName).appendingPathComponent("thumbnails")
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
            model.style = .only(detent: asset.previousDetent)
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
  }
}
