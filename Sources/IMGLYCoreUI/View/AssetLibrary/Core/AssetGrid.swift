import SwiftUI

struct AssetGridAxisKey: EnvironmentKey {
  static let defaultValue = Axis.vertical
}

struct AssetGridItemsKey: EnvironmentKey {
  static let defaultValue = [GridItem(.flexible())]
}

struct AssetGridSpacingKey: EnvironmentKey {
  static let defaultValue: CGFloat? = nil
}

struct AssetGridEdgesKey: EnvironmentKey {
  static let defaultValue: Edge.Set = .all
}

struct AssetGridPaddingKey: EnvironmentKey {
  static let defaultValue: CGFloat? = nil
}

struct AssetGridMessageTextOnlyKey: EnvironmentKey {
  static let defaultValue = false
}

struct AssetGridMaxItemCountKey: EnvironmentKey {
  static let defaultValue = Int.max
}

@_spi(Internal) public typealias AssetGridPlaceholderCount = @Sendable @MainActor (
  _ state: AssetLoader.Models.State,
  _ maxItemCount: Int
) -> Int

struct AssetGridPlaceholderCountKey: EnvironmentKey {
  static let defaultValue: AssetGridPlaceholderCount = { state, maxItemCount in
    state == .loading ? min(20, maxItemCount) : 0
  }
}

struct AssetGridSourcePaddingKey: EnvironmentKey {
  static let defaultValue: CGFloat = 0
}

@_spi(Internal) public typealias AssetGridItemIndex = @Sendable @MainActor (_ asset: AssetLoader.Asset) -> AnyHashable?

struct AssetGridItemIndexKey: EnvironmentKey {
  static let defaultValue: AssetGridItemIndex = { _ in nil }
}

@_spi(Internal) public typealias AssetGridOnAppear = @Sendable @MainActor (ScrollViewProxy) -> Void

struct AssetGridOnAppearKey: EnvironmentKey {
  static let defaultValue: AssetGridOnAppear = { _ in }
}

struct AssetGridExcludedSourcesKey: EnvironmentKey {
  static let defaultValue = Set<String>()
}

extension EnvironmentValues {
  var imglyAssetGridAxis: AssetGridAxisKey.Value {
    get { self[AssetGridAxisKey.self] }
    set { self[AssetGridAxisKey.self] = newValue }
  }

  var imglyAssetGridItems: AssetGridItemsKey.Value {
    get { self[AssetGridItemsKey.self] }
    set { self[AssetGridItemsKey.self] = newValue }
  }

  var imglyAssetGridSpacing: AssetGridSpacingKey.Value {
    get { self[AssetGridSpacingKey.self] }
    set { self[AssetGridSpacingKey.self] = newValue }
  }

  var imglyAssetGridEdges: AssetGridEdgesKey.Value {
    get { self[AssetGridEdgesKey.self] }
    set { self[AssetGridEdgesKey.self] = newValue }
  }

  var imglyAssetGridPadding: AssetGridPaddingKey.Value {
    get { self[AssetGridPaddingKey.self] }
    set { self[AssetGridPaddingKey.self] = newValue }
  }

  var imglyAssetGridMessageTextOnly: AssetGridMessageTextOnlyKey.Value {
    get { self[AssetGridMessageTextOnlyKey.self] }
    set { self[AssetGridMessageTextOnlyKey.self] = newValue }
  }

  var imglyAssetGridMaxItemCount: AssetGridMaxItemCountKey.Value {
    get { self[AssetGridMaxItemCountKey.self] }
    set { self[AssetGridMaxItemCountKey.self] = newValue }
  }

  var imglyAssetGridPlaceholderCount: AssetGridPlaceholderCountKey.Value {
    get { self[AssetGridPlaceholderCountKey.self] }
    set { self[AssetGridPlaceholderCountKey.self] = newValue }
  }

  var imglyAssetGridSourcePadding: AssetGridSourcePaddingKey.Value {
    get { self[AssetGridSourcePaddingKey.self] }
    set { self[AssetGridSourcePaddingKey.self] = newValue }
  }

  var imglyAssetGridItemIndex: AssetGridItemIndexKey.Value {
    get { self[AssetGridItemIndexKey.self] }
    set { self[AssetGridItemIndexKey.self] = newValue }
  }

  var imglyAssetGridOnAppear: AssetGridOnAppearKey.Value {
    get { self[AssetGridOnAppearKey.self] }
    set { self[AssetGridOnAppearKey.self] = newValue }
  }

  var imglyAssetGridExcludedSources: AssetGridExcludedSourcesKey.Value {
    get { self[AssetGridExcludedSourcesKey.self] }
    set { self[AssetGridExcludedSourcesKey.self] = newValue }
  }
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

  @ViewBuilder private let item: (AssetItem) -> Item
  @ViewBuilder private let empty: (_ search: String) -> Empty
  @ViewBuilder private let first: () -> First
  @ViewBuilder private let more: () -> More

  @State private var selectedAsset: AssetLoader.Asset?

  private var isAttributionPresented: Binding<Bool> {
    Binding(
      get: { selectedAsset != nil },
      set: { if !$0 { selectedAsset = nil } }
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
          LazyHGrid(rows: items, spacing: spacing) {
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
          LazyVGrid(columns: items, spacing: spacing) {
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
                Label("Retry", systemImage: "arrow.clockwise")
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
