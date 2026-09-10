import SwiftUI

@_spi(Internal) public typealias AssetGridPlaceholderCount = @MainActor (
  _ state: AssetLoader.Models.State,
  _ maxItemCount: Int
) -> Int

@_spi(Internal) public typealias AssetGridItemIndex = @MainActor (_ asset: AssetLoader.Asset) -> AnyHashable?

@_spi(Internal) public typealias AssetGridOnAppear = @MainActor (ScrollViewProxy) -> Void

extension EnvironmentValues {
  @Entry var imglyAssetGridAxis = Axis.vertical
  @Entry var imglyAssetGridItems = AssetGridItems(gridItems: [GridItem(.flexible())])
  @Entry var imglyAssetGridSpacing: CGFloat?
  @Entry var imglyAssetGridEdges = Edge.Set.all
  @Entry var imglyAssetGridPadding: CGFloat?
  @Entry var imglyAssetGridMessageTextOnly = false
  @Entry var imglyAssetGridMaxItemCount = Int.max
  @Entry var imglyAssetGridPlaceholderCount: AssetGridPlaceholderCount = { state, maxItemCount in
    state == .loading ? min(20, maxItemCount) : 0
  }

  @Entry var imglyAssetGridSourcePadding: CGFloat = 0
  @Entry var imglyAssetGridItemIndex: AssetGridItemIndex = { _ in nil }
  @Entry var imglyAssetGridOnAppear: AssetGridOnAppear = { _ in }
  @Entry var imglyAssetGridExcludedSources = Set<String>()
  @Entry var imglyAssetGridShouldShowSingleItem: Bool = true
}

@_spi(Internal) public struct AssetGrid<Item: View, Empty: View, First: View, More: View>: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  @EnvironmentObject private var data: AssetLoader.Data
  @Environment(\.imglyAssetGridAxis) private var axis
  @Environment(\.imglyAssetGridItems) private var items
  @Environment(\.imglyAssetGridSpacing) private var spacing
  @Environment(\.imglyAssetGridEdges) private var edges
  @Environment(\.imglyAssetGridPadding) private var padding
  @Environment(\.imglyAssetGridMessageTextOnly) private var messageTextOnly
  @Environment(\.imglyAssetGridMaxItemCount) private var maxItemCount
  @Environment(\.imglyAssetGridPlaceholderCount) private var placeholderCount
  @Environment(\.imglyAssetGridSourcePadding) private var sourcePadding
  @Environment(\.imglyAssetGridItemIndex) private var itemIndex
  @Environment(\.imglyAssetGridOnAppear) private var onAppear
  @Environment(\.imglyAssetGridExcludedSources) private var excludedSources
  @Environment(\.imglyAssetGridShouldShowSingleItem) private var shouldShowSingleItem

  @ViewBuilder private let item: (AssetItem) -> Item
  @ViewBuilder private let empty: (_ search: String) -> Empty
  @ViewBuilder private let first: () -> First
  @ViewBuilder private let more: () -> More

  @State private var selectedAsset: AssetLoader.Asset?

  private var isAttributionPresented: Binding<Bool> {
    Binding(
      get: { selectedAsset != nil },
      set: { if !$0 { selectedAsset = nil } },
    )
  }

  @_spi(Internal) public init(
    @ViewBuilder item: @escaping (AssetItem) -> Item,
    @ViewBuilder empty: @escaping (_ search: String) -> Empty = { _ in Message.noElements },
    @ViewBuilder first: @escaping () -> First = { EmptyView() },
    @ViewBuilder more: @escaping () -> More = { EmptyView() }
  ) {
    self.item = item
    self.empty = empty
    self.first = first
    self.more = more
  }

  private func loadMoreContentIfNeeded(currentItem asset: AssetLoader.Asset) {
    guard data.model.assets.count <= maxItemCount else {
      return
    }
    // Revise if this still works with 20 `excludedSources`... !
    let threshold = data.model.assets.dropLast(20).last ?? data.model.assets.last
    if asset.id == threshold?.id {
      data.model.loadNextPage()
    }
  }

  @ViewBuilder private func grid(@ViewBuilder content: @escaping () -> some View) -> some View {
    switch axis {
    case .horizontal:
      ScrollViewReader { proxy in
        AssetLibraryScrollView(axis: .horizontal, showsIndicators: false) {
          LazyHGrid(rows: items.gridItems, spacing: spacing) {
            content()
          }
          .padding(edges, padding)
          .task {
            onAppear(proxy)
          }
        }
      }
    case .vertical:
      ScrollViewReader { proxy in
        AssetLibraryScrollView(axis: .vertical, showsIndicators: true) {
          LazyVGrid(columns: items.gridItems, spacing: spacing) {
            content()
          }
          .padding(edges, padding)
          .task {
            onAppear(proxy)
          }
        }
      }
    }
  }

  @ViewBuilder private var placeholderView: some View {
    grid {
      ForEach(0 ..< placeholderCount(data.model.state, maxItemCount), id: \.self) { _ in
        item(.placeholder)
      }
    }
    .allowsHitTesting(false)
  }

  @ViewBuilder private var messageView: some View {
    switch data.model.state {
    case .loading:
      placeholderView
        .imgly.shimmer()
    case .loaded:
      placeholderView
        .mask {
          let colors: [Color] = [.black, .clear]
          Rectangle().fill(.linearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
            .flipsForRightToLeftLayoutDirection(true)
        }
        .overlay {
          empty(data.model.search.query ?? "")
        }
    case .error:
      placeholderView
        .mask {
          let colors: [Color] = [.black, .clear]
          Rectangle().fill(.linearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
            .flipsForRightToLeftLayoutDirection(true)
        }
        .overlay {
          VStack(spacing: 30) {
            Message.noService
            if !messageTextOnly {
              Button {
                data.model.retry()
              } label: {
                Label {
                  Text(.imgly.localized("ly_img_editor_asset_library_button_retry"))
                } icon: {
                  Image(systemName: "arrow.clockwise")
                }
              }
              .buttonStyle(.bordered)
              .tint(.secondary)
            }
          }
        }
    }
  }

  @ViewBuilder private var contentView: some View {
    grid {
      first()
      let items = Array(data.model.assets
        .filter { !excludedSources.contains($0.sourceID) }
        .prefix(maxItemCount)
        .enumerated())
      if items.count != 1 || shouldShowSingleItem {
        ForEach(items, id: \.element.id) { index, asset in
          let padding: CGFloat = {
            if index > 0 {
              return asset.sourceID != data.model.assets[index - 1].sourceID ? sourcePadding : 0
            }
            return 0
          }()

          item(.asset(asset))
            .modifier(AttributionSheet(asset: asset) {
              selectedAsset = asset
            })
            .id(itemIndex(asset) ?? asset.id as AnyHashable)
            .onAppear {
              loadMoreContentIfNeeded(currentItem: asset)
            }
            .padding(EdgeInsets(top: 0, leading: padding, bottom: 0, trailing: 0))
        }
      }
      if case .loading = data.model.state {
        item(.placeholder)
          .imgly.shimmer()
      }
      if data.model.assets.count >= maxItemCount, data.model.total > maxItemCount || data.model.total < 0 {
        more()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .aspectRatio(1, contentMode: .fit)
      }
    }
    .sheet(isPresented: isAttributionPresented) {
      if let asset = selectedAsset {
        Attribution(asset: asset)
      }
    }
    .allowsHitTesting(!interactor.isAddingAsset)
  }

  @_spi(Internal) public var body: some View {
    if data.model.isValid {
      contentView
    } else {
      messageView
    }
  }
}

struct AssetGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
