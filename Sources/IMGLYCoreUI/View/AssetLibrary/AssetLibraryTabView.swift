import IMGLYCore
import SwiftUI

public struct AssetLibraryTabView<Content: View, Label: View>: View {
  private let title: String
  @ViewBuilder private let content: () -> Content
  @ViewBuilder private let label: (_ title: LocalizedStringKey) -> Label

  public init(_ title: String,
              @ViewBuilder content: @escaping () -> Content,
              @ViewBuilder label: @escaping (_ title: LocalizedStringKey) -> Label) {
    self.title = title
    self.content = content
    self.label = label
  }

  var localizedTitle: LocalizedStringKey { .init(title) }

  @Environment(\.imglyIsAssetLibraryMoreTab) private var isMoreTab
  @Environment(\.imglyAssetLibraryTitleDisplayMode) private var titleDisplayMode

  @ViewBuilder var tabContent: some View {
    TabContent(title: title, content: content)
  }

  @ViewBuilder var labelContent: some View {
    label(localizedTitle)
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
      .tag(title)
    }
  }
}

private struct TabContent<Content: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content

  @Environment(\.imglyDismissButtonView) private var dismissButtonView
  @EnvironmentObject private var searchState: AssetLibrarySearchState
  private var localizedTitle: LocalizedStringKey { .init(title) }

  var body: some View {
    content()
      .navigationTitle(localizedTitle)
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

struct AssetLibraryTitleDisplayModeKey: EnvironmentKey {
  static let defaultValue: NavigationBarItem.TitleDisplayMode = .automatic
}

extension EnvironmentValues {
  var imglyAssetLibraryTitleDisplayMode: NavigationBarItem.TitleDisplayMode {
    get { self[AssetLibraryTitleDisplayModeKey.self] }
    set { self[AssetLibraryTitleDisplayModeKey.self] = newValue }
  }
}

struct AssetLibraryTabView_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
