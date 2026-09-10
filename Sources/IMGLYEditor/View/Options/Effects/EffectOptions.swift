@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct EffectOptions<Item: View>: View {
  @Binding var selection: AssetSelection?
  @ViewBuilder var item: (AssetLoader.Asset, Binding<EffectSheetState>) -> Item
  let identifier: ((AssetLoader.Asset) -> AnyHashable?)?
  let sources: [AssetLoader.SourceData]
  @Binding var sheetState: EffectSheetState

  @EnvironmentObject private var interactor: Interactor
  @StateObject private var searchState = AssetLibrarySearchState()

  @ViewBuilder private var grid: some View {
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
        NoneItem(selection: $selection)
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
      Spacer()
    }
    .background(Color(.systemGroupedBackground))
  }

  var body: some View {
    switch sheetState {
    case .selection:
      grid
    case let .properties(asset):
      EffectPropertyOptions(
        title: asset.title,
        properties: refreshedProperties(from: asset),
        backTitle: asset.backTitle,
        previousDetent: asset.previousDetent,
        sheetState: $sheetState,
      )
    }
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
