import SwiftUI

@_spi(Internal) public struct AssetLibrarySection<Destination: View, Preview: View, Accessory: View>: View {
  private let title: String
  @ViewBuilder private let destination: () -> Destination
  @ViewBuilder private let preview: () -> Preview
  @ViewBuilder private let accessory: () -> Accessory

  @_spi(Internal) public init(_ title: String,
                              @ViewBuilder destination: @escaping () -> Destination,
                              @ViewBuilder preview: @escaping () -> Preview,
                              @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }) {
    self.title = title
    self.destination = destination
    self.preview = preview
    self.accessory = accessory
  }

  var localizedTitle: LocalizedStringKey { .init(title) }

  @State var totalResults: Int?
  @Environment(\.imglyDismissButtonView) private var dismissButtonView
  @EnvironmentObject private var searchState: AssetLibrarySearchState

  @ViewBuilder var label: some View {
    if let totalResults {
      if totalResults < 0 || totalResults > 999 {
        Text("More")
      } else {
        Text("\(totalResults)")
      }
    }
    Image(systemName: "chevron.forward")
  }

  @MainActor
  @ViewBuilder var content: some View {
    destination()
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

  @_spi(Internal) public var body: some View {
    Section {
      preview()
        .environment(\.imglySeeAllView, SeeAll(destination: AnyView(erasing: content)))
        .onPreferenceChange(AssetLoader.TotalResultsKey.self) { newValue in
          totalResults = newValue
        }
    } header: {
      HStack(spacing: 26) {
        Text(localizedTitle)
          .font(.headline)
        Spacer()
        accessory()
          .font(.subheadline)
        NavigationLink {
          content
        } label: {
          label
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .accessibilityLabel(.init("More \(title)"))
        }
      }
      .padding(.top, 16)
      .padding([.leading, .trailing], 16)
    }
  }
}

struct AssetLibrarySeeAllKey: EnvironmentKey {
  static let defaultValue: SeeAll? = nil
}

extension EnvironmentValues {
  var imglySeeAllView: SeeAll? {
    get { self[AssetLibrarySeeAllKey.self] }
    set { self[AssetLibrarySeeAllKey.self] = newValue }
  }
}

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
        Text("See All")
          .font(.caption.weight(.medium))
      }
      .foregroundColor(.primary)
    }
  }
}

struct AssetLibraryDismissButtonKey: EnvironmentKey {
  static let defaultValue: DismissButton? = nil
}

extension EnvironmentValues {
  var imglyDismissButtonView: DismissButton? {
    get { self[AssetLibraryDismissButtonKey.self] }
    set { self[AssetLibraryDismissButtonKey.self] = newValue }
  }
}

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
