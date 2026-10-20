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

  /// The top safe area of the sheet content. iOS 26 puts the title bar into it in a form sheet and in
  /// landscape, but lets the bar float over the content in an iPhone portrait bottom sheet.
  @State private var topSafeAreaInset: CGFloat = 0

  /// The distance from the sheet top to the bottom edge of the iOS 26 title bar.
  private let titleBarClearance: CGFloat = 50

  /// Pads the strip down to the title bar only where the safe area does not do it already, so the
  /// gap never doubles and the tile labels stay inside the sheet.
  private var floatingTitleBarInset: CGFloat {
    usesLegacyDesign ? 0 : max(0, titleBarClearance - topSafeAreaInset)
  }

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
      .padding(.top, floatingTitleBarInset)
      Spacer()
    }
    .background {
      GeometryReader { proxy in
        Color.clear
          .onAppear { topSafeAreaInset = proxy.safeAreaInsets.top }
          .onChange(of: proxy.safeAreaInsets.top) { topSafeAreaInset = $0 }
      }
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
