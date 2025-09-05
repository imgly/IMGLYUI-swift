import SwiftUI

@_spi(Internal) public struct AssetLibrarySection<
  Destination: View,
  Preview: View,
  Accessory: View,
  Action: View,
>: View {
  private let title: LocalizedStringResource
  @ViewBuilder private let destination: () -> Destination
  @ViewBuilder private let preview: () -> Preview
  @ViewBuilder private let accessory: () -> Accessory
  @ViewBuilder private let action: () -> Action

  @StateObject private var configuration = AssetLibrarySectionConfiguration()

  @_spi(Internal) public init(_ title: LocalizedStringResource,
                              @ViewBuilder destination: @escaping () -> Destination,
                              @ViewBuilder preview: @escaping () -> Preview,
                              @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() },
                              @ViewBuilder action: @escaping () -> Action = { EmptyView() }) {
    self.title = title
    self.destination = destination
    self.preview = preview
    self.accessory = accessory
    self.action = action
  }

  @State var totalResults: Int?
  @Environment(\.imglyDismissButtonView) private var dismissButtonView
  @EnvironmentObject private var searchState: AssetLibrarySearchState

  @ViewBuilder var label: some View {
    if let totalResults {
      if totalResults < 0 || totalResults > 999 {
        Text(.imgly.localized("ly_img_editor_asset_library_button_more"))
      } else {
        Text(verbatim: "\(totalResults)")
      }
    }
    Image(systemName: "chevron.forward")
  }

  @MainActor
  @ViewBuilder var content: some View {
    destination()
      .environmentObject(configuration)
      .navigationTitle(Text(title))
      .toolbar {
        ToolbarItem {
          HStack(spacing: 16) {
            if configuration.isSearchAllowed {
              SearchButton()
              dismissButtonView
            } else {
              dismissButtonView
                .buttonStyle(.plain)
            }
          }
        }
      }
      .onAppear {
        searchState.setPrompt(for: title)
      }
  }

  @_spi(Internal) public var body: some View {
    Section {
      preview()
        .environment(\.imglySeeAllView, SeeAll(destination: AnyView(erasing: content)))
        .onPreferenceChange(AssetLoader.TotalResultsKey.self) { newValue in
          totalResults = newValue
        }
    } header: {
      HStack(spacing: 26) {
        Text(title)
          .font(.headline)
        Spacer()
        accessory()
          .font(.subheadline)
        action()
          .font(.subheadline.weight(.semibold).monospacedDigit())
        if configuration.isNavigationAllowed {
          NavigationLink {
            content
          } label: {
            label
              .font(.subheadline.weight(.semibold).monospacedDigit())
          }
        }
      }
      .environmentObject(configuration)
      .padding(.top, 16)
      .padding([.leading, .trailing], 16)
    }
  }
}

extension EnvironmentValues {
  @Entry var imglySeeAllView: SeeAll?
}

@MainActor
struct SeeAll: View {
  let destination: AnyView

  var body: some View {
    NavigationLink {
      destination
    } label: {
      VStack(spacing: 4) {
        ZStack {
          Image(systemName: "arrow.forward")
            .font(.title2)
          Circle()
            .stroke()
            .frame(width: 48, height: 48)
            .foregroundColor(.secondary)
        }
        Text(.imgly.localized("ly_img_editor_asset_library_button_see_all"))
          .font(.caption.weight(.medium))
      }
      .foregroundColor(.primary)
    }
  }
}

extension EnvironmentValues {
  @Entry var imglyDismissButtonView: DismissButton?
}

@MainActor
struct DismissButton: View {
  let content: AnyView

  var body: some View {
    content
  }
}

struct AssetLibrarySection_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
