@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

public extension AssetLoader.SourceData {
  init(demoSource: Engine.DemoAssetSource, config: AssetLoader.QueryData = .init()) {
    self.init(id: demoSource.rawValue, config: config)
  }

  init(defaultSource: Engine.DefaultAssetSource, config: AssetLoader.QueryData = .init()) {
    self.init(id: defaultSource.rawValue, config: config)
  }
}

@MainActor
public struct DefaultAssetLibrary: AssetLibrary {
  @Environment(\.imglyAssetLibrarySceneMode) var sceneMode

  public enum Tab: CaseIterable {
    case elements, uploads, videos, audio, images, text, shapes, stickers
  }

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

  @AssetLibraryBuilder public static var videos: AssetLibraryContent {
    AssetLibrarySource.videoUpload(.title("Camera Roll"), source: .init(demoSource: .videoUpload))
    AssetLibrarySource.video(.title("Videos"), source: .init(demoSource: .video))
  }

  @AssetLibraryBuilder public static var audio: AssetLibraryContent {
    AssetLibrarySource.audioUpload(.title("Uploads"), source: .init(demoSource: .audioUpload))
    AssetLibrarySource.audio(.title("Audio"), source: .init(demoSource: .audio))
  }

  @AssetLibraryBuilder public static var images: AssetLibraryContent {
    AssetLibrarySource.imageUpload(.title("Camera Roll"), source: .init(demoSource: .imageUpload))
    AssetLibrarySource.image(.title("Images"), source: .init(demoSource: .image))
  }

  let text = AssetLibrarySource.text(.title("Text"), source: .init(id: TextAssetSource.id))

  @AssetLibraryBuilder public static var shapes: AssetLibraryContent {
    AssetLibrarySource.shape(.title("Basic"), source: .init(
      defaultSource: .vectorPath, config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/vectorpaths"])))
    AssetLibrarySource.shape(.title("Abstract"), source: .init(
      defaultSource: .vectorPath, config: .init(groups: ["//ly.img.cesdk.vectorpaths.abstract/category/abstract"])))
  }

  @AssetLibraryBuilder public static var stickers: AssetLibraryContent {
    AssetLibrarySource.sticker(.titleForGroup { group in
      if let name = group?.split(separator: "/").last {
        return name.capitalized
      } else {
        return "Stickers"
      }
    }, source: .init(defaultSource: .sticker))
  }

  func tabContent(_ tab: Tab) -> AssetLibraryContent {
    switch tab {
    case .elements: return AssetLibraryGroup.empty
    case .uploads: return uploads
    case .videos: return videos
    case .audio: return audio
    case .images: return images
    case .text: return text
    case .shapes: return shapes
    case .stickers: return stickers
    }
  }

  func elementsContent(_ tab: Tab) -> AssetLibraryContent {
    switch tab {
    case .elements: return AssetLibraryGroup.empty
    case .uploads: return AssetLibraryGroup.upload("Camera Roll") { uploads }
    case .videos: return AssetLibraryGroup.video("Videos") { videos }
    case .audio: return AssetLibraryGroup.audio("Audio") { audio }
    case .images: return AssetLibraryGroup.image("Images") { images }
    case .text: return text
    case .shapes: return AssetLibraryGroup.shape("Shapes") { shapes }
    case .stickers: return AssetLibraryGroup.sticker("Stickers") { stickers }
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

  @ViewBuilder public static func elementsLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "books.vertical")
  }

  @ViewBuilder public static func uploadsLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "camera")
  }

  @ViewBuilder public static func videosLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "play.rectangle")
  }

  @ViewBuilder public static func audioLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "music.note.list")
  }

  @ViewBuilder public static func imagesLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "photo")
  }

  @ViewBuilder public static func textLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "textformat.alt")
  }

  @ViewBuilder public static func shapesLabel(_ title: LocalizedStringKey) -> some View {
    Label(title, systemImage: "square.on.circle")
  }

  @ViewBuilder public static func stickersLabel(_ title: LocalizedStringKey) -> some View {
    // Fixes light/dark mode fill issue with `"face.smiling"` for iOS 16.
    Label {
      Text(title)
    } icon: {
      Image("custom.face.smiling", bundle: .module)
    }
  }

  @ViewBuilder var elementsTab: some View {
    AssetLibraryTab("Elements") { elements } label: { Self.elementsLabel($0) }
  }

  @ViewBuilder var uploadsTab: some View {
    AssetLibraryTab("Camera Roll") { uploads } label: { Self.uploadsLabel($0) }
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

  @ViewBuilder var textTab: some View {
    AssetLibraryTabView("Text") { text.content } label: { Self.textLabel($0) }
  }

  @ViewBuilder var shapesTab: some View {
    AssetLibraryTab("Shapes") { shapes } label: { Self.shapesLabel($0) }
  }

  @ViewBuilder public var stickersTab: some View {
    AssetLibraryTab("Stickers") { stickers } label: { Self.stickersLabel($0) }
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
