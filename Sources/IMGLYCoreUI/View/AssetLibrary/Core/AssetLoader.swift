@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

/// A loader that fetches asset data from asset sources.
public struct AssetLoader: ViewModifier {
  private let sources: [SourceData]
  @Binding private var search: QueryData

  init(sources: [SourceData], search: Binding<QueryData>, order: ItemOrder, perPage: Int) {
    self.sources = sources
    _search = search
    _data = .init(wrappedValue: AssetLoader
      .Data(model: .search(sources, for: search.wrappedValue, order: order, perPage: perPage)))
  }

  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  @StateObject private var data: AssetLoader.Data

  private func search(_ query: QueryData) {
    data.model.search(sources, for: query)
  }

  @_spi(Internal) public func body(content: Content) -> some View {
    content
      .environmentObject(data)
      .preference(key: AssetLoader.TotalResultsKey.self, value: data.model.total)
      .onChange(of: search) { newValue in
        search(newValue)
      }
      .imgly.onReceive(.AssetSourceDidChange) { notification in
        guard let userInfo = notification.userInfo,
              let sourceID = userInfo["sourceID"] as? String, sources.contains(where: {
                sourceID == $0.id
              }) else {
          return
        }
        search(search)
      }
      .task(id: data.model.id) {
        let interactor = interactor
        let id = data.model.id
        let results = await withTaskGroup(of: (UUID, AssetLoader.Model)?.self) { group in
          for (uuid, model) in data.model.models {
            guard case let .loading(query) = model.state, !Task.isCancelled else {
              continue
            }
            group.addTask {
              var model = model
              do {
                let response = try await interactor.findAssets(sourceID: query.source.id, query: query.request)
                if Task.isCancelled {
                  return nil
                }
                model.loaded(.init(query: query, response: response))
                return (uuid, model)
              } catch {
                if Task.isCancelled {
                  return nil
                }
                model.error(.init(query: query, error: error))
                return (uuid, model)
              }
            }
          }

          var results = [UUID: Model]()
          results.reserveCapacity(data.model.sources.count)
          for await result in group {
            if Task.isCancelled {
              return results
            }
            if let result {
              results[result.0] = result.1
            }
          }
          return results
        }

        if Task.isCancelled {
          return
        }
        assert(id == data.model.id)
        data.model.fetched(results)
      }
  }
}

// MARK: - Public interface

public extension AssetLoader {
  /// An asset source definition.
  struct SourceData: Hashable, Sendable {
    /// The asset source ID.
    public let id: String
    /// The configuration query to limit the results of this asset source.
    public let config: QueryData
    let expandGroups: Bool

    /// Creates an asset source definition.
    /// - Parameters:
    ///   - id: The asset source ID.
    ///   - config: The configuration query to limit the results of this asset source.
    public init(id: String, config: QueryData = .init()) {
      self.id = id
      self.config = config
      expandGroups = false
    }

    private init(_ other: Self, expandGroups: Bool) {
      id = other.id
      config = other.config
      self.expandGroups = expandGroups
    }

    func expandedGroups(_ value: Bool) -> Self {
      .init(self, expandGroups: value)
    }

    /// Limits source to `group` and disables `expandGroups`.
    func narrowed(to group: String) -> Self {
      .init(id: id, config: config.narrowed(by: .init(groups: [group])))
    }
  }

  /// A wrapper for `IMGLYEngine.AssetQueryData` without explicit page handling.
  struct QueryData: Hashable, Sendable {
    ///  A query string used for (fuzzy) searching of labels and tags.
    public let query: String?
    /// Tags are searched with the query parameter, but this search is fuzzy.
    /// If one needs to get assets with exactly the tag (from a tag cloud or filter)
    /// this query parameter should be used.
    public let tags: [String]?
    /// Query only these groups.
    public let groups: IMGLYEngine.Groups?
    /// Filter out assets with this groups.
    public let excludedGroups: IMGLYEngine.Groups?
    /// Choose the locale of the label and tags for localized search and filtering.
    public let locale: IMGLYEngine.Locale?
    /// The order to sort by if the asset source supports sorting.
    /// If set to None, the order is the same as the assets were added to the source.
    public let sortingOrder: IMGLYEngine.SortingOrder
    /// The key that identifies the meta data value to sort by or 'id' to sort by the asset ID.
    /// If empty, the assets are sorted by the index.
    public let sortKey: IMGLYEngine.SortKey?
    /// Sort assets that are marked as active first.
    public let sortActiveFirst: Bool

    /// Initializes a request for querying assets.
    /// - Parameters:
    ///   - query: A query string used for (fuzzy) searching of label and tags.
    ///   - tags:  Tags are searched with the query parameter, but this search is fuzzy.
    ///   - groups: Query only these groups.
    ///   - excludedGroups: Filter out assets with this groups.
    ///   - locale: Choose the locale of the label and tags for localized search and filtering.
    ///   - sortingOrder: The order to sort by if the asset source supports sorting.
    ///   - sortKey: The key that identifies the meta data value to sort by or 'id' to sort by the asset ID.
    ///   - sortActiveFirst: Sort assets that are marked as active first.
    public init(query: String? = nil, tags: [String]? = nil,
                groups: IMGLYEngine.Groups? = nil,
                excludedGroups: IMGLYEngine.Groups? = nil,
                locale: IMGLYEngine.Locale? = "en",
                sortingOrder: IMGLYEngine.SortingOrder = .none,
                sortKey: IMGLYEngine.SortKey? = nil,
                sortActiveFirst: Bool = false) {
      self.query = query
      self.tags = tags
      self.groups = groups
      self.excludedGroups = excludedGroups
      self.locale = locale
      self.sortingOrder = sortingOrder
      self.sortKey = sortKey
      self.sortActiveFirst = sortActiveFirst
    }

    func narrowed(by other: Self) -> Self {
      func intersection(_ lhs: [String]?, _ rhs: [String]?) -> [String]? {
        if let rhs {
          let set = Set<String>(rhs)
          return lhs?.filter { set.contains($0) } ?? rhs
        } else {
          return lhs
        }
      }

      func union(_ lhs: [String]?, _ rhs: [String]?) -> [String]? {
        if let rhs {
          lhs ?? [] + rhs
        } else {
          lhs
        }
      }

      return .init(
        query: other.query ?? query,
        tags: intersection(other.tags, tags),
        groups: intersection(other.groups, groups),
        excludedGroups: union(other.excludedGroups, excludedGroups),
        locale: other.locale ?? locale,
        sortingOrder: other.sortingOrder != .none ? other.sortingOrder : sortingOrder,
        sortKey: other.sortKey ?? sortKey,
        sortActiveFirst: other.sortActiveFirst
      )
    }
  }
}

// MARK: - Internal interface

@_spi(Internal) public extension AssetLoader {
  struct TotalResultsKey: PreferenceKey {
    @_spi(Internal) public static let defaultValue: Int? = nil
    @_spi(Internal) public static func reduce(value: inout Int?, nextValue: () -> Int?) {
      let lhs = value ?? 0
      let rhs = nextValue() ?? 0
      if lhs < 0 || rhs < 0 {
        value = -1
      } else {
        value = lhs + rhs
      }
    }
  }

  class Data: ObservableObject {
    @Published @_spi(Internal) public var model: Models

    init(model: Models) {
      _model = .init(initialValue: model)
    }
  }

  struct Models {
    // swiftlint:disable:next nesting
    @_spi(Internal) public enum State {
      case loading, loaded, error
    }

    fileprivate let id: UUID

    private var order: ItemOrder
    private var perPage: Int

    let sources: [(UUID, SourceData)]
    let models: [UUID: Model]
    @_spi(Internal) public let search: QueryData
    @_spi(Internal) public let state: State

    private init(_ id: UUID, _ sources: [(UUID, SourceData)], _ models: [UUID: Model],
                 _ state: Models.State, _ search: QueryData, _ order: ItemOrder,
                 _ perPage: Int) {
      self.id = id
      self.sources = sources
      self.models = models
      self.state = state
      self.search = search
      self.order = order
      self.perPage = perPage

      let orderedAssetsBySources = sources.compactMap { uuid, _ in
        if let model = models[uuid] {
          model.assets
        } else {
          nil
        }
      }

      assets = (order == .alternating ? Self.alternatingElements(of: orderedAssetsBySources) : orderedAssetsBySources
        .flatMap { $0 })
    }

    fileprivate static func search(
      _ sources: [AssetLoader.SourceData],
      for query: AssetLoader.QueryData,
      order: AssetLoader.ItemOrder,
      perPage: Int
    ) -> Self {
      let sources = sources.map { (UUID(), $0) }
      var models = [UUID: AssetLoader.Model]()
      for source in sources {
        models[source.0] = .search(source.1, query, perPage)
      }
      return .init(UUID(), sources, models, .loading, query, order, perPage)
    }

    fileprivate mutating func search(_ sources: [AssetLoader.SourceData], for query: AssetLoader.QueryData) {
      self = .search(sources, for: query, order: order, perPage: perPage)
    }

    fileprivate mutating func fetched(_ results: [UUID: AssetLoader.Model]) {
      let results = models.merging(results) { _, new in new }
      let error = results.allSatisfy { _, result in
        if case .error = result.state {
          true
        } else {
          false
        }
      }
      if error {
        self = .init(id, sources, results, .error, search, order, perPage)
      } else {
        self = .init(id, sources, results, .loaded, search, order, perPage)
      }
    }

    @_spi(Internal) public mutating func loadNextPage() {
      var models = models
      var willLoadNextPage = false
      for (uuid, _) in sources {
        willLoadNextPage = willLoadNextPage || models[uuid]?.loadNextPage() ?? false
      }
      if willLoadNextPage {
        self = .init(UUID(), sources, models, .loading, search, order, perPage)
      }
    }

    @_spi(Internal) public mutating func retry() {
      var models = models
      var willRetry = false
      for (uuid, _) in sources {
        willRetry = willRetry || models[uuid]?.retry() ?? false
      }
      if willRetry {
        self = .init(UUID(), sources, models, .loading, search, order, perPage)
      }
    }

    @_spi(Internal) public let assets: [AssetLoader.Asset]

    private static func alternatingElements<T>(of arrays: [[T]]) -> [T] {
      let maxCount = arrays.reduce(0) { max($0, $1.count) }
      let totalCount = arrays.reduce(0) { $0 + $1.count }
      var result = [T]()
      result.reserveCapacity(totalCount)

      for i in 0 ..< maxCount {
        for array in arrays where i < array.count {
          result.append(array[i])
        }
      }

      return result
    }

    @_spi(Internal) public var isValid: Bool {
      models.contains { $0.value.isValid }
    }

    @_spi(Internal) public var total: Int {
      models.reduce(0) {
        if $0 < 0 || $1.value.total < 0 {
          -1
        } else {
          $0 + $1.value.total
        }
      }
    }
  }

  struct Model: Sendable {
    fileprivate let id: UUID
    @_spi(Internal) public let state: Source
    private let _assets: Assets
    @_spi(Internal) public var assets: [AssetLoader.Asset] { _assets.assets }
    private var perPage: Int

    private init(_ id: UUID, _ source: Source, _ assets: Assets, _ perPage: Int) {
      self.id = id
      self.perPage = perPage
      state = source
      _assets = assets
    }

    fileprivate static func search(_ source: AssetLoader.SourceData, _ data: AssetLoader.QueryData,
                                   _ perPage: Int) -> Self {
      .init(UUID(), .loading(.init(source, data, perPage: perPage)), AssetLoader.Assets(), perPage)
    }

    fileprivate mutating func search(_ source: AssetLoader.SourceData, _ data: AssetLoader.QueryData) {
      self = .search(source, data, perPage)
    }

    fileprivate mutating func loaded(_ result: AssetLoader.Result) {
      var assets = _assets
      assets.append(AssetLoader.Assets(result))
      self = .init(id, .loaded(result), assets, perPage)
    }

    @_spi(Internal) public mutating func loadNextPage() -> Bool {
      if case let .loaded(result) = state, result.hasNextPage {
        self = .init(UUID(), .loading(result.nextPage), _assets, perPage)
        return true
      } else {
        return false
      }
    }

    @_spi(Internal) public mutating func retry() -> Bool {
      if case let .error(error) = state {
        self = .init(UUID(), .loading(error.query), _assets, perPage)
        return true
      } else {
        return false
      }
    }

    fileprivate mutating func error(_ error: AssetLoader.Error) {
      self = .init(id, .error(error), _assets, perPage)
    }

    @_spi(Internal) public var isValid: Bool {
      if case .error = state {
        false
      } else {
        !assets.isEmpty
      }
    }

    @_spi(Internal) public var total: Int {
      if case let .loaded(result) = state {
        result.response.total
      } else {
        0
      }
    }
  }

  struct Query: Equatable, Sendable {
    @_spi(Internal) public let source: SourceData
    @_spi(Internal) public let data: QueryData
    fileprivate let page: Int
    fileprivate let perPage: Int

    fileprivate init(_ source: SourceData, _ data: QueryData, page: Int = 0, perPage: Int) {
      self.source = source
      self.data = data
      self.page = page
      self.perPage = perPage
    }

    fileprivate var request: AssetQueryData {
      let data = data.narrowed(by: source.config)
      return .init(query: data.query, page: page,
                   tags: data.tags, groups: data.groups, excludedGroups: data.excludedGroups,
                   locale: data.locale, perPage: perPage, sortingOrder: data.sortingOrder,
                   sortKey: data.sortKey)
    }
  }

  struct Result: Sendable {
    /// The used `query` that produced the `response`.
    @_spi(Internal) public let query: Query
    @_spi(Internal) public let response: AssetQueryResult

    @_spi(Internal) public var hasNextPage: Bool {
      response.nextPage > 0
    }

    fileprivate var nextPage: AssetLoader.Query {
      .init(query.source, query.data, page: response.nextPage, perPage: query.perPage)
    }
  }

  struct Error: Sendable {
    /// The used `query` that produced the `error`.
    @_spi(Internal) public let query: Query
    @_spi(Internal) public let error: Swift.Error
  }

  enum Source: Sendable {
    case loading(Query)
    case loaded(Result)
    case error(Error)
  }

  struct Asset: Identifiable, Sendable, Hashable {
    // Don't rely on `result.context.sourceID` as this value depends on the (user) implementation of `findAssets`.
    @_spi(Internal) public let sourceID: String
    @_spi(Internal) public let result: AssetResult

    @_spi(Internal) public var thumbURLorURL: URL? {
      result.thumbURL ?? result.url
    }

    @_spi(Internal) public var previewURLorURL: URL? {
      result.previewURL ?? result.url
    }

    @_spi(Internal) public var labelOrTypefaceName: String? {
      result.label ?? result.payload?.typeface?.name
    }

    @_spi(Internal) public var id: String {
      sourceID + result.id // Make sure that id is really unique across sources.
    }

    @_spi(Internal) public init(sourceID: String, result: AssetResult) {
      self.sourceID = sourceID
      self.result = result
    }
  }

  enum ItemOrder {
    case alternating
    case sorted
  }
}

private extension AssetLoader {
  struct Assets: Sendable {
    private var ids: Set<String>
    var assets: [Asset]

    init() {
      ids = []
      assets = []
    }

    init(_ result: AssetLoader.Result) {
      var ids = Set<String>()
      var assets = [Asset]()

      result.response.assets
        .map { Asset(sourceID: result.query.source.id, result: $0) }
        .forEach {
          if ids.contains($0.id) {
            print("Ignoring duplicate asset with id: \($0.id)")
          } else {
            ids.insert($0.id)
            assets.append($0)
          }
        }

      self.ids = ids
      self.assets = assets
    }

    mutating func append(_ other: Assets) {
      assets.append(contentsOf: other.assets.filter {
        if ids.contains($0.id) {
          print("Ignoring duplicate asset with id: \($0.id)")
          return false
        } else {
          return true
        }
      })
      ids = ids.union(other.ids)
    }
  }
}

struct AssetLoader_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
