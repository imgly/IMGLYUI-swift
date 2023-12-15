import IMGLYCore
import SwiftUI

@_spi(Internal) public struct AssetLibrarySourcesKey: EnvironmentKey {
  @_spi(Internal) public static var defaultValue: [AssetLoader.SourceData] = []
}

@_spi(Internal) public extension EnvironmentValues {
  var imglyAssetLibrarySources: AssetLibrarySourcesKey.Value {
    get { self[AssetLibrarySourcesKey.self] }
    set { self[AssetLibrarySourcesKey.self] = newValue }
  }
}

public struct AssetLibrarySource<Destination: View, Preview: View, Accessory: View>: AssetLibraryContent, View {
  public var id: Int {
    var hasher = Hasher()
    hasher.combine(title(nil))
    hasher.combine(sources)
    return hasher.finalize()
  }

  public var sources: [AssetLoader.SourceData] { [source] }
  public var view: AnyView { AnyView(erasing: body) }

  /// The `Destination` content view of the asset source without section(s).
  public var content: some View {
    destination()
      .imgly.assetLibrary(sources: sources)
  }

  private let title: (_ group: String?) -> String
  private let source: AssetLoader.SourceData
  @ViewBuilder private let destination: () -> Destination
  @ViewBuilder private let preview: () -> Preview
  @ViewBuilder private let accessory: () -> Accessory

  public enum Mode {
    /// A single `AssetLibrarySection` is created which contains all groups for the asset source configuration.
    case title(String)
    /// Multiple `AssetLibrarySection`s are created. One for each group of the asset source configuration.
    /// If `groups` of the asset source configuration is `nil` or empty avilable groups will be queried from the asset
    /// source. `group` for the `.titleForGroup` closure is `nil` when there are no groups available. In this case the
    /// resulting behavior is identical to the single `.title` mode and the `.titleForGroup` closure should return a
    /// valid title.
    case titleForGroup((_ group: String?) -> String = { $0 ?? "Assets" })
  }

  public init(_ mode: Mode,
              source: AssetLoader.SourceData,
              @ViewBuilder destination: @escaping () -> Destination,
              @ViewBuilder preview: @MainActor @escaping () -> Preview = { AssetPreview.imageOrVideo },
              @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }) {
    switch mode {
    case let .title(title):
      self.title = { _ in title }
      self.source = source
    case let .titleForGroup(titles):
      title = titles
      self.source = source.expandedGroups(true)
    }
    self.destination = destination
    self.preview = preview
    self.accessory = accessory
  }

  @ViewBuilder private func sections(_ groups: [String]) -> some View {
    ForEach(groups, id: \.self) { group in
      let sources = [source.narrowed(to: group)]
      AssetLibrarySection(title(group)) {
        destination().imgly.assetLibrary(sources: sources)
      } preview: {
        preview().imgly.assetLibrary(sources: sources)
      } accessory: {
        accessory().imgly.assetLibrary(sources: sources)
      }
    }
  }

  @ViewBuilder public var body: some View {
    if source.expandGroups {
      if let groups = source.config.groups, !groups.isEmpty {
        sections(groups)
      } else {
        ExpandGroups(sourceID: source.id) { groups in
          if let groups, !groups.isEmpty {
            sections(groups)
          } else {
            // Fallback, no groups available
            let sources = [source.expandedGroups(false)]
            AssetLibrarySection(title(nil)) {
              destination().imgly.assetLibrary(sources: sources)
            } preview: {
              preview().imgly.assetLibrary(sources: sources)
            } accessory: {
              accessory().imgly.assetLibrary(sources: sources)
            }
          }
        }
      }
    } else {
      AssetLibrarySection(title(nil)) {
        content
      } preview: {
        preview().imgly.assetLibrary(sources: sources)
      } accessory: {
        accessory().imgly.assetLibrary(sources: sources)
      }
    }
  }

  public func debugPrint(_ level: Int) {
    print(String(repeating: "  ", count: level) + "Source",
          title(nil), id, source.id, source.expandGroups, source.config.groups ?? "")
  }
}

private struct ExpandGroups<Content: View>: View {
  let sourceID: String
  @ViewBuilder let content: (_ groups: [String]?) -> Content
  @State private var groups: [String]?
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor

  var body: some View {
    content(groups)
      .task {
        groups = try? await interactor.getGroups(sourceID: sourceID)
      }
  }
}

struct AssetLibrarySource_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
