@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct EffectOptions<Item: View, Properties: View>: View {
  @Binding var selection: AssetSelection?
  @ViewBuilder var item: (AssetLoader.Asset, Binding<EffectSheetState>) -> Item
  let identifier: ((AssetLoader.Asset) -> AnyHashable?)?
  let sources: [AssetLoader.SourceData]
  @Binding var sheetState: EffectSheetState
  /// Whether the leading "None" tile (clears the applied asset) is shown. Off for grids where None has no
  /// meaning, e.g. caption presets.
  var showNoneItem = true
  @ViewBuilder var properties: (AssetProperties) -> Properties

  @EnvironmentObject private var interactor: Interactor
  @StateObject private var searchState = AssetLibrarySearchState()

  private var grid: some View {
    VStack {
      AssetGrid { asset in
        switch asset {
        case let .asset(asset):
          item(asset, $sheetState)
        case .placeholder:
          SelectableEffectItem(title: "", selected: false) {
            GridItemBackground()
              .aspectRatio(1, contentMode: .fit)
          }
        }
      } empty: { _ in
        Message.noElements
      } first: {
        if showNoneItem {
          NoneItem(selection: $selection)
        }
      } more: {
        EmptyView()
      }
      .imgly.assetGrid(axis: .horizontal)
      .imgly.assetGrid(items: [GridItem(.adaptive(minimum: 80, maximum: 100))])
      .imgly.assetGrid(spacing: 8)
      .imgly.assetGrid(edges: [.leading, .trailing])
      .imgly.assetGrid(padding: 16)
      .imgly.assetGridPlaceholderCount { _, _ in
        10
      }
      .imgly.assetGrid(messageTextOnly: true)
      .imgly.assetGrid(sourcePadding: 16)
      .imgly.assetGridItemIndex { identifier?($0) }
      .imgly.assetGridOnAppear { $0.scrollTo(selection?.identifier) }
      .imgly.assetLoader(sources: sources, order: .sorted, perPage: 65)
      .frame(height: 110, alignment: .top)
      .environmentObject(searchState)
      // Clear the floating iOS 26 Liquid Glass title bar; no-op on the legacy design.
      .padding(.top, usesLegacyDesign ? 0 : 44)
      Spacer()
    }
    .background(Color(.systemGroupedBackground))
  }

  var body: some View {
    switch sheetState {
    case .selection:
      grid
    case let .properties(asset):
      properties(asset)
    }
  }
}

extension EffectOptions where Properties == RefreshedEffectPropertyOptions {
  /// Uses the generic ``EffectPropertyOptions`` list as the properties page.
  init(
    selection: Binding<AssetSelection?>,
    @ViewBuilder item: @escaping (AssetLoader.Asset, Binding<EffectSheetState>) -> Item,
    identifier: ((AssetLoader.Asset) -> AnyHashable?)?,
    sources: [AssetLoader.SourceData],
    sheetState: Binding<EffectSheetState>,
    showNoneItem: Bool = true,
  ) {
    self.init(
      selection: selection,
      item: item,
      identifier: identifier,
      sources: sources,
      sheetState: sheetState,
      showNoneItem: showNoneItem,
      properties: { RefreshedEffectPropertyOptions(asset: $0, sheetState: sheetState) },
    )
  }
}

/// Renders the generic `EffectPropertyOptions` after refreshing asset-backed property values from the engine.
struct RefreshedEffectPropertyOptions: View {
  let asset: AssetProperties
  @Binding var sheetState: EffectSheetState

  @EnvironmentObject private var interactor: Interactor

  var body: some View {
    EffectPropertyOptions(
      title: asset.title,
      properties: refreshedProperties(from: asset),
      backTitle: asset.backTitle,
      previousStyle: asset.previousStyle,
      sheetState: $sheetState,
    )
  }

  private func refreshedProperties(from asset: AssetProperties) -> [EffectProperty] {
    guard let engine = interactor.engine else { return asset.properties }
    return asset.properties.map { property in
      guard let assetContext = property.assetContext,
            let blockID = property.id else { return property }
      let refreshed = AnimationPropertyDefinitions.refreshedAssetProperty(
        assetContext.assetProperty,
        from: engine,
        blockID: blockID,
      )
      guard let refreshed else { return property }
      var updatedContext = assetContext
      updatedContext.assetProperty = refreshed
      return EffectProperty(
        label: property.label,
        value: property.value,
        property: property.property,
        id: property.id,
        assetContext: updatedContext,
      )
    }
  }
}
