@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Public interface

public extension View {
  /// Gets a namespace holder for `IMGLY` compatible types.
  var imgly: IMGLY<Self> { .init(self) }
}

// MARK: - Internal interface

@_spi(Internal) public extension View {
  var usesLegacyDesign: Bool {
    #if swift(>=6.2)
      if #available(iOS 26.0, *) {
        return Bundle.main.object(forInfoDictionaryKey: "UIDesignRequiresCompatibility") as? Bool ?? false
      }
    #endif
    return true
  }
}

@_spi(Internal) public extension IMGLY where Wrapped: View {
  @MainActor
  func assetLibrary(interactor: some AssetLibraryInteractor) -> some View {
    wrapped.environmentObject(AnyAssetLibraryInteractor(erasing: interactor))
  }

  @MainActor
  func assetLibraryDismissButton(_ content: () -> some View) -> some View {
    wrapped.environment(\.imglyDismissButtonView, DismissButton(content: AnyView(erasing: content())))
  }

  func assetLibrary(titleDisplayMode: NavigationBarItem.TitleDisplayMode) -> some View {
    wrapped.environment(\.imglyAssetLibraryTitleDisplayMode, titleDisplayMode)
  }

  func assetLibrary(sceneMode: SceneMode?) -> some View {
    wrapped.environment(\.imglyAssetLibrarySceneMode, sceneMode)
  }

  func assetLibrary(sources: [AssetLoader.SourceData]) -> some View {
    wrapped.environment(\.imglyAssetLibrarySources, sources)
  }

  /// Automatically passes the sources and search query to the ``AssetLoader`` from the environment.
  @MainActor
  func assetLoader() -> some View {
    wrapped.modifier(SearchedAssetLoader())
  }

  @MainActor
  func assetLoader(
    sources: [AssetLoader.SourceData],
    search: Binding<AssetLoader.QueryData> = .constant(.init()),
    order: AssetLoader.ItemOrder = .alternating,
    perPage: Int = 30,
  ) -> some View {
    wrapped.modifier(AssetLoader(sources: sources, search: search, order: order, perPage: perPage))
  }

  func assetGrid(axis: Axis) -> some View { wrapped.environment(\.imglyAssetGridAxis, axis) }
  func assetGrid(items: [GridItem]) -> some View { wrapped.environment(
    \.imglyAssetGridItems,
    AssetGridItems(gridItems: items),
  ) }
  func assetGrid(spacing: CGFloat?) -> some View { wrapped.environment(\.imglyAssetGridSpacing, spacing) }
  func assetGrid(edges: Edge.Set) -> some View { wrapped.environment(\.imglyAssetGridEdges, edges) }
  func assetGrid(padding: CGFloat?) -> some View { wrapped.environment(\.imglyAssetGridPadding, padding) }
  func assetGrid(messageTextOnly: Bool)
    -> some View { wrapped.environment(\.imglyAssetGridMessageTextOnly, messageTextOnly) }
  func assetGrid(maxItemCount: Int) -> some View { wrapped.environment(\.imglyAssetGridMaxItemCount, maxItemCount) }
  func assetGridPlaceholderCount(_ placeholderCount: @escaping AssetGridPlaceholderCount)
    -> some View { wrapped.environment(\.imglyAssetGridPlaceholderCount, placeholderCount) }
  func assetGrid(sourcePadding: CGFloat)
    -> some View { wrapped.environment(\.imglyAssetGridSourcePadding, sourcePadding) }
  func assetGridItemIndex(_ itemIndex: @escaping AssetGridItemIndex)
    -> some View { wrapped.environment(\.imglyAssetGridItemIndex, itemIndex) }
  func assetGridOnAppear(_ onAppear: @escaping AssetGridOnAppear)
    -> some View { wrapped.environment(\.imglyAssetGridOnAppear, onAppear) }
  func assetGrid(excludedSources: Set<String>)
    -> some View { wrapped.environment(\.imglyAssetGridExcludedSources, excludedSources) }
  func assetGrid(shouldShowSingleItem: Bool)
    -> some View { wrapped.environment(\.imglyAssetGridShouldShowSingleItem, shouldShowSingleItem) }
  @MainActor
  func buildInfo(ciBuildsHost: String, githubRepo: String) -> some View {
    wrapped.safeAreaInset(edge: .bottom, spacing: 0) {
      BuildInfo(ciBuildsHost: ciBuildsHost, githubRepo: githubRepo)
    }
  }

  func nonDefaultPreviewSettings() -> some View {
    wrapped.previewDisplayName("Landscape, dark mode, RTL")
      .previewInterfaceOrientation(.landscapeRight)
      .preferredColorScheme(.dark)
      .environment(\.layoutDirection, .rightToLeft)
  }

  func shimmer() -> some View {
    wrapped.modifier(Shimmer())
  }
}

extension IMGLY where Wrapped: View {
  @MainActor
  func searchableAssetLibraryTab() -> some View {
    wrapped.modifier(SearchableAssetLibraryTab())
  }

  @MainActor
  func assetFileUploader(isPresented: Binding<Bool>, allowedContentTypes: [UTType],
                         onCompletion: @escaping AssetFileUploader.Completion = { _ in }) -> some View {
    wrapped.modifier(AssetFileUploader(isPresented: isPresented, allowedContentTypes: allowedContentTypes,
                                       onCompletion: onCompletion))
  }

  func inverseMask(alignment: Alignment = .center, @ViewBuilder _ mask: () -> some View) -> some View {
    wrapped.mask {
      Rectangle()
        .overlay(alignment: alignment) {
          mask()
            .blendMode(.destinationOut)
        }
    }
  }

  func onReceive(
    _ name: Notification.Name,
    center: NotificationCenter = .default,
    object: AnyObject? = nil,
    perform action: @escaping (Notification) -> Void,
  ) -> some View {
    wrapped.onReceive(center.publisher(for: name, object: object), perform: action)
  }
}
