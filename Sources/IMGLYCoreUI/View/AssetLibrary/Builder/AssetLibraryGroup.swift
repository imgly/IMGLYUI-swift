import SwiftUI

/// A group of hierarchical asset library content. It is used within an ``AssetLibraryBuilder`` context.
public struct AssetLibraryGroup<Preview: View>: AssetLibraryContent, View {
  public var id: Int {
    var hasher = Hasher()
    hasher.combine(title)
    for component in components {
      hasher.combine(component.id)
    }
    return hasher.finalize()
  }

  public var sources: [AssetLoader.SourceData] { components.flatMap(\.sources) }
  public var view: AnyView { AnyView(erasing: body) }

  private let title: String?
  let components: [AssetLibraryContent]
  @ViewBuilder private let preview: () -> Preview

  init(components: [AssetLibraryContent],
       @ViewBuilder preview: @MainActor @escaping () -> Preview = { EmptyView() }) {
    self.components = components
    self.preview = preview
    title = nil
  }

  /// Creates a group of asset library `content`. It is displayed as a section with a `title` and a `preview`.
  /// - Parameters:
  ///   - title: The displayed name of the group.
  ///   - content: The asset library content.
  ///   - preview: The preview view of the group.
  public init(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent,
              @ViewBuilder preview: @MainActor @escaping () -> Preview = { AssetPreview.imageOrVideo }) {
    let content = content()
    self.title = title
    if let content = content as? AssetLibraryGroup<EmptyView> {
      components = content.components
    } else {
      components = [content]
    }
    self.preview = preview
  }

  @ViewBuilder private var scrollView: some View {
    AssetLibraryScrollView {
      ForEach(components, id: \.id) {
        $0.view
      }
      .padding(.bottom, 16)
    }
  }

  public var body: some View {
    if let title {
      AssetLibrarySection(title) {
        scrollView
      } preview: {
        preview().imgly.assetLibrary(sources: sources)
      }
    } else {
      scrollView
    }
  }

  public func debugPrint(_ level: Int) {
    print(String(repeating: "  ", count: level) + "Group", components.count, title ?? "", id)
    for component in components {
      component.debugPrint(level + 1)
    }
  }
}

struct AssetLibraryGroup_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
