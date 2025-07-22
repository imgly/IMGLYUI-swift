import IMGLYCore
import SwiftUI

@_spi(Internal) public struct AssetLibrarySourcesKey: EnvironmentKey {
  @_spi(Internal) public static let defaultValue: [AssetLoader.SourceData] = []
}

@_spi(Internal) public extension EnvironmentValues {
  var imglyAssetLibrarySources: AssetLibrarySourcesKey.Value {
    get { self[AssetLibrarySourcesKey.self] }
    set { self[AssetLibrarySourcesKey.self] = newValue }
  }
}

/// The leaf nodes of hierarchical asset library content. It is used within an ``AssetLibraryBuilder`` context.
public struct AssetLibrarySource<Destination: View, Preview: View, Accessory: View>: AssetLibraryContent, View {
  public var id: Int {
    var hasher = Hasher()
    let title = title(nil)
    hasher.combine(title.key)
    hasher.combine(title.table)
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

  private let title: (_ group: String?) -> LocalizedStringResource
  private let source: AssetLoader.SourceData
  @ViewBuilder private let destination: () -> Destination
  @ViewBuilder private let preview: () -> Preview
  @ViewBuilder private let accessory: () -> Accessory

  /// The display mode of an asset source.
  public enum Mode {
    /// A single section is created which contains all groups for the asset source configuration.
    case title(LocalizedStringResource)
    /// Multiple sections are created. One for each group of the asset source configuration.
    /// If `groups` of the asset source configuration is `nil` or empty available groups will be queried from the asset
    /// source. `group` for the `.titleForGroup` closure is `nil` when there are no groups available. In this case the
    /// resulting behavior is identical to the single `.title` mode and the `.titleForGroup` closure should return a
    /// valid title.
    case titleForGroup((_ group: String?)
      -> LocalizedStringResource = { if let group = $0 { "\(group)" } else { "Assets" } })
  }

  /// Creates one or more sections for an asset `source` depending on the used display `mode`. Each section is displayed
  /// with a `preview` and an optional `accessory` view. The `destination` view is used to browse the entire content of
  /// the asset source.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  ///   - destination: The destination view to browse the entire content of the asset source.
  ///   - preview: The section preview view.
  ///   - accessory: The accessory view.
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

  public var body: some View {
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
