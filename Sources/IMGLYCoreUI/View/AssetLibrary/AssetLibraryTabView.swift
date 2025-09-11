import IMGLYCore
import SwiftUI

/// A tab used in an ``AssetLibrary`` to display any `View`.
public struct AssetLibraryTabView<Content: View, Label: View>: View {
  private let title: LocalizedStringResource
  @ViewBuilder private let content: () -> Content
  @ViewBuilder private let label: (_ title: LocalizedStringResource) -> Label

  /// Creates an asset library tab with any `content`.
  /// - Parameters:
  ///   - title: The title of the tab.
  ///   - content: The content.
  ///   - label: The label of the tab. The `title` is passed to this closure.
  public init(_ title: LocalizedStringResource,
              @ViewBuilder content: @escaping () -> Content,
              @ViewBuilder label: @escaping (_ title: LocalizedStringResource) -> Label) {
    self.title = title
    self.content = content
    self.label = label
  }

  @Environment(\.imglyIsAssetLibraryMoreTab) private var isMoreTab
  @Environment(\.imglyAssetLibraryTitleDisplayMode) private var titleDisplayMode

  @MainActor
  @ViewBuilder var tabContent: some View {
    TabContent(title: title, content: content)
  }

  @ViewBuilder var labelContent: some View {
    label(title)
  }

  public var body: some View {
    if isMoreTab {
      NavigationLink {
        tabContent
      } label: {
        labelContent
          .symbolVariant(.fill)
      }
    } else {
      NavigationView {
        tabContent
          .navigationBarTitleDisplayMode(titleDisplayMode)
      }
      .navigationViewStyle(.stack)
      .imgly.searchableAssetLibraryTab()
      .tabItem {
        labelContent
      }
      .tag(title.key)
    }
  }
}

private struct TabContent<Content: View>: View {
  let title: LocalizedStringResource
  @ViewBuilder let content: () -> Content

  @Environment(\.imglyDismissButtonView) private var dismissButtonView
  @EnvironmentObject private var searchState: AssetLibrarySearchState

  var body: some View {
    content()
      .navigationTitle(Text(title))
      .toolbar {
        ToolbarItem {
          HStack(spacing: 16) {
            SearchButton()
            dismissButtonView
          }
        }
      }
      .onAppear {
        searchState.setPrompt(for: title)
      }
  }
}

extension EnvironmentValues {
  @Entry var imglyAssetLibraryTitleDisplayMode = NavigationBarItem.TitleDisplayMode.automatic
}

struct AssetLibraryTabView_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
