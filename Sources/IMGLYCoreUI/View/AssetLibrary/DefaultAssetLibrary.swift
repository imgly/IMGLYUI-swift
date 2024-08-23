@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

public extension AssetLoader.SourceData {
  /// Creates an asset source definition for demo asset sources.
  /// - Parameters:
  ///   - demoSource: The demo asset source.
  ///   - config: The configuration query to limit the results of this asset source.
  init(demoSource: Engine.DemoAssetSource, config: AssetLoader.QueryData = .init()) {
    self.init(id: demoSource.rawValue, config: config)
  }

  /// Creates an asset source definition for default asset sources.
  /// - Parameters:
  ///   - defaultSource: The default asset source.
  ///   - config: The configuration query to limit the results of this asset source.
  init(defaultSource: Engine.DefaultAssetSource, config: AssetLoader.QueryData = .init()) {
    self.init(id: defaultSource.rawValue, config: config)
  }
}

/// This is a predefined `AssetLibrary` intended to quickly customize some parts of the default asset library without
/// implementing a complete `AssetLibrary` from scratch.
@MainActor
public struct DefaultAssetLibrary: AssetLibrary {
  @Environment(\.imglyAssetLibrarySceneMode) var sceneMode

  /// A tab for a specific asset type.
  public enum Tab: CaseIterable {
    case elements, uploads, videos, audio, images, text, shapes, stickers
  }

  /// Creates a default asset library with a selection of `tabs`.
  /// - Parameter tabs: A custom selection and ordering of the available tabs.
  public init(tabs: [Tab] = Tab.allCases) {
    self.tabs = tabs.uniqued()
    videos = Self.videos
    audio = Self.audio
    images = Self.images
    shapes = Self.shapes
    stickers = Self.stickers
  }

  private init(tabs: [Tab],
               videos: AssetLibraryContent,
               audio: AssetLibraryContent,
               images: AssetLibraryContent,
               shapes: AssetLibraryContent,
               stickers: AssetLibraryContent) {
    self.tabs = tabs
    self.videos = videos
    self.audio = audio
    self.images = images
    self.shapes = shapes
    self.stickers = stickers
  }

  let tabs: [Tab]
  let videos, audio, images, shapes, stickers: AssetLibraryContent

  /// Modify the video asset library content.
  /// - Parameter videos: The video asset library content.
  /// - Returns: The modified `DefaultAssetLibrary`.
  public func videos(@AssetLibraryBuilder videos: @MainActor () -> AssetLibraryContent) -> Self {
    .init(
      tabs: tabs,
      videos: videos(),
      audio: audio,
      images: images,
      shapes: shapes,
      stickers: stickers
    )
  }

  /// Modify the audio asset library content.
  /// - Parameter audio: The audio asset library content.
  /// - Returns: The modified `DefaultAssetLibrary`.
  public func audio(@AssetLibraryBuilder audio: @MainActor () -> AssetLibraryContent) -> Self {
    .init(
      tabs: tabs,
      videos: videos,
      audio: audio(),
      images: images,
      shapes: shapes,
      stickers: stickers
    )
  }

  /// Modify the image asset library content.
  /// - Parameter images: The image asset library content.
  /// - Returns: The modified `DefaultAssetLibrary`.
  public func images(@AssetLibraryBuilder images: @MainActor () -> AssetLibraryContent) -> Self {
    .init(
      tabs: tabs,
      videos: videos,
      audio: audio,
      images: images(),
      shapes: shapes,
      stickers: stickers
    )
  }

  /// Modify the shape asset library content.
  /// - Parameter shapes: The shape asset library content.
  /// - Returns: The modified `DefaultAssetLibrary`.
  public func shapes(@AssetLibraryBuilder shapes: @MainActor () -> AssetLibraryContent) -> Self {
    .init(
      tabs: tabs,
      videos: videos,
      audio: audio,
      images: images,
      shapes: shapes(),
      stickers: stickers
    )
  }

  /// Modify the sticker asset library content.
  /// - Parameter stickers: The sticker asset library content.
  /// - Returns: The modified `DefaultAssetLibrary`.
  public func stickers(@AssetLibraryBuilder stickers: @MainActor () -> AssetLibraryContent) -> Self {
    .init(
      tabs: tabs,
      videos: videos,
      audio: audio,
      images: images,
      shapes: shapes,
      stickers: stickers()
    )
  }

  @AssetLibraryBuilder var uploads: AssetLibraryContent {
    AssetLibrarySource.imageUpload(.title("Images"), source: .init(demoSource: .imageUpload))
    if sceneMode == .video {
      AssetLibrarySource.videoUpload(.title("Videos"), source: .init(demoSource: .videoUpload))
    }
  }

  @AssetLibraryBuilder var videosAndImages: AssetLibraryContent {
    AssetLibraryGroup.video("Videos") { videos }
    AssetLibraryGroup.image("Images") { images }
    AssetLibraryGroup.upload("Photo Roll") {
      AssetLibrarySource.imageUpload(.title("Images"), source: .init(demoSource: .imageUpload))
      AssetLibrarySource.videoUpload(.title("Videos"), source: .init(demoSource: .videoUpload))
    }
  }

  /// The default video asset library content.
  @AssetLibraryBuilder public static var videos: AssetLibraryContent {
    AssetLibrarySource.video(.title("Videos"), source: .init(demoSource: .video))
    AssetLibrarySource.videoUpload(.title("Photo Roll"), source: .init(demoSource: .videoUpload))
  }

  /// The default audio asset library content.
  @AssetLibraryBuilder public static var audio: AssetLibraryContent {
    AssetLibrarySource.audio(.title("Audio"), source: .init(demoSource: .audio))
    AssetLibrarySource.audioUpload(.title("Uploads"), source: .init(demoSource: .audioUpload))
  }

  /// The default image asset library content.
  @AssetLibraryBuilder public static var images: AssetLibraryContent {
    AssetLibrarySource.image(.title("Images"), source: .init(demoSource: .image))
    AssetLibrarySource.imageUpload(.title("Photo Roll"), source: .init(demoSource: .imageUpload))
  }

  let text = AssetLibrarySource.text(.title("Text"), source: .init(id: TextAssetSource.id))

  /// The default shape asset library content.
  @AssetLibraryBuilder public static var shapes: AssetLibraryContent {
    AssetLibrarySource.shape(.title("Basic"), source: .init(
      defaultSource: .vectorPath, config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/vectorpaths"])))
    AssetLibrarySource.shape(.title("Abstract"), source: .init(
      defaultSource: .vectorPath, config: .init(groups: ["//ly.img.cesdk.vectorpaths.abstract/category/abstract"])))
  }

  /// The default sticker asset library content.
  @AssetLibraryBuilder public static var stickers: AssetLibraryContent {
    AssetLibrarySource.sticker(.titleForGroup { group in
      if let name = group?.split(separator: "/").last {
        name.capitalized
      } else {
        "Stickers"
      }
    }, source: .init(defaultSource: .sticker))
  }

  func tabContent(_ tab: Tab) -> AssetLibraryContent {
    switch tab {
    case .elements: AssetLibraryGroup.empty
    case .uploads: uploads
    case .videos: videos
    case .audio: audio
    case .images: images
    case .text: text
    case .shapes: shapes
    case .stickers: stickers
    }
  }

  func elementsContent(_ tab: Tab) -> AssetLibraryContent {
    switch tab {
    case .elements: AssetLibraryGroup.empty
    case .uploads: AssetLibraryGroup.upload("Photo Roll") { uploads }
    case .videos: AssetLibraryGroup.video("Videos") { videos }
    case .audio: AssetLibraryGroup.audio("Audio") { audio }
    case .images: AssetLibraryGroup.image("Images") { images }
    case .text: text
    case .shapes: AssetLibraryGroup.shape("Shapes") { shapes }
    case .stickers: AssetLibraryGroup.sticker("Stickers") { stickers }
    }
  }

  @ViewBuilder func tabView(_ tab: Tab) -> some View {
    switch tab {
    case .elements: elementsTab
    case .uploads: uploadsTab
    case .videos: videosTab
    case .audio: audioTab
    case .images: imagesTab
    case .text: textTab
    case .shapes: shapesTab
    case .stickers: stickersTab
    }
  }

  var activeTabs: [Tab] {
    tabs.filter { tab in
      let isNotEmpty = !tabContent(tab).isEmpty
      switch tab {
      case .elements:
        return true
      case .videos, .audio:
        return isNotEmpty && sceneMode == .video
      default:
        return isNotEmpty
      }
    }
  }

  var activeElements: [Tab] {
    activeTabs.filter { $0 != .elements }
  }

  @AssetLibraryBuilder var elements: AssetLibraryContent {
    for tab in activeElements {
      elementsContent(tab)
    }
  }

  /// The default label for the elements tab.
  @ViewBuilder public static func elementsLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "books.vertical")
  }

  /// The default label for the uploads tab.
  @ViewBuilder public static func uploadsLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "camera")
  }

  /// The default label for the videos tab.
  @ViewBuilder public static func videosLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "play.rectangle")
  }

  /// The default label for the audio tab.
  @ViewBuilder public static func audioLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "music.note.list")
  }

  /// The default label for the images tab.
  @ViewBuilder public static func imagesLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "photo")
  }

  /// The default label for the text tab.
  @ViewBuilder public static func textLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "textformat.alt")
  }

  /// The default label for the shapes tab.
  @ViewBuilder public static func shapesLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "square.on.circle")
  }

  /// The default label for the stickers tab.
  @ViewBuilder public static func stickersLabel(_ title: LocalizedStringKey) -> some View {
    // Fixes light/dark mode fill issue with `"face.smiling"` for iOS 16.
    Label {
      Text(title)
    } icon: {
      Image("custom.face.smiling", bundle: .module)
    }
  }

  @ViewBuilder var uploadsTab: some View {
    AssetLibraryTab("Photo Roll") { uploads } label: { Self.uploadsLabel($0) }
  }

  @ViewBuilder public var elementsTab: some View {
    AssetLibraryTab("Elements") { elements } label: { Self.elementsLabel($0) }
  }

  @ViewBuilder public var videosTab: some View {
    AssetLibraryTab("Videos") { videos } label: { Self.videosLabel($0) }
  }

  @ViewBuilder public var audioTab: some View {
    AssetLibraryTab("Audio") { audio } label: { Self.audioLabel($0) }
  }

  @ViewBuilder public var imagesTab: some View {
    AssetLibraryTab("Images") { images } label: { Self.imagesLabel($0) }
  }

  @ViewBuilder public var textTab: some View {
    AssetLibraryTabView("Text") { text.content } label: { Self.textLabel($0) }
  }

  @ViewBuilder public var shapesTab: some View {
    AssetLibraryTab("Shapes") { shapes } label: { Self.shapesLabel($0) }
  }

  @ViewBuilder public var stickersTab: some View {
    AssetLibraryTab("Stickers") { stickers } label: { Self.stickersLabel($0) }
  }

  @ViewBuilder public var clipsTab: some View {
    AssetLibraryTab("Clips") { videosAndImages } label: { _ in EmptyView() }
  }

  @ViewBuilder public var overlaysTab: some View {
    AssetLibraryTab("Overlays") { videosAndImages } label: { _ in EmptyView() }
  }

  @ViewBuilder public var stickersAndShapesTab: some View {
    AssetLibraryTab("Stickers") {
      stickers
      shapes
    } label: { _ in EmptyView() }
  }

  @ViewBuilder func tabViews(_ tabs: some RandomAccessCollection<Tab>) -> some View {
    ForEach(tabs, id: \.self) {
      tabView($0)
    }
  }

  public var body: some View {
    TabView {
      let activeTabs = activeTabs
      if activeTabs.count > 5 {
        if activeTabs.contains(.elements), activeTabs.contains(.uploads),
           activeTabs.count == 6 {
          let tabsWithoutUploads = activeTabs.filter { $0 != .uploads }
          tabViews(tabsWithoutUploads)
        } else {
          let tabs = activeTabs.prefix(4)
          let moreTabs = activeTabs.dropFirst(4)
          tabViews(tabs)
          AssetLibraryMoreTab {
            tabViews(moreTabs)
          }
        }
      } else {
        tabViews(activeTabs)
      }
    }
  }
}

struct DefaultAssetLibrary_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
