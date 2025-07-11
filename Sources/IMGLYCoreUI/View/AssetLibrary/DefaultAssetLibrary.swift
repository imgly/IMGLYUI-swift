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

/// This is a predefined ``AssetLibrary`` intended to quickly customize some parts of the default asset library without
/// implementing a complete ``AssetLibrary`` from scratch.
@MainActor
public struct DefaultAssetLibrary: AssetLibrary {
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
  /// - Returns: The modified ``DefaultAssetLibrary``.
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
  /// - Returns: The modified ``DefaultAssetLibrary``.
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
  /// - Returns: The modified ``DefaultAssetLibrary``.
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
  /// - Returns: The modified ``DefaultAssetLibrary``.
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
  /// - Returns: The modified ``DefaultAssetLibrary``.
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

  @AssetLibraryBuilder func uploads(_ sceneMode: SceneMode?) -> AssetLibraryContent {
    // Don't use upload strings here as it shouldn't state "Photo Roll" twice as this is already the parent.
    AssetLibrarySource.imageUpload(
      .title(.imgly.localized("ly_img_editor_asset_library_section_images")),
      source: .init(demoSource: .imageUpload)
    )
    if sceneMode == .video {
      AssetLibrarySource.videoUpload(
        .title(.imgly.localized("ly_img_editor_asset_library_section_videos")),
        source: .init(demoSource: .videoUpload)
      )
    }
  }

  @AssetLibraryBuilder var videosAndImages: AssetLibraryContent {
    AssetLibraryGroup.video(.imgly.localized("ly_img_editor_asset_library_section_videos")) { videos }
    AssetLibraryGroup.image(.imgly.localized("ly_img_editor_asset_library_section_images")) { images }
    AssetLibraryGroup.upload(.imgly.localized("ly_img_editor_asset_library_section_uploads")) {
      // Don't use upload strings here as it shouldn't state "Photo Roll" twice as this is already the parent.
      AssetLibrarySource.imageUpload(
        .title(.imgly.localized("ly_img_editor_asset_library_section_images")),
        source: .init(demoSource: .imageUpload)
      )
      AssetLibrarySource.videoUpload(
        .title(.imgly.localized("ly_img_editor_asset_library_section_videos")),
        source: .init(demoSource: .videoUpload)
      )
    }
  }

  /// The default video asset library content.
  @AssetLibraryBuilder public static var videos: AssetLibraryContent {
    AssetLibrarySource.video(
      .title(.imgly.localized("ly_img_editor_asset_library_section_videos")),
      source: .init(demoSource: .video)
    )
    AssetLibrarySource.videoUpload(
      .title(.imgly.localized("ly_img_editor_asset_library_section_video_uploads")),
      source: .init(demoSource: .videoUpload)
    )
  }

  /// The default audio asset library content.
  @AssetLibraryBuilder public static var audio: AssetLibraryContent {
    AssetLibrarySource.audio(
      .title(.imgly.localized("ly_img_editor_asset_library_section_audio")),
      source: .init(demoSource: .audio)
    )
    AssetLibrarySource.audioUpload(
      .title(.imgly.localized("ly_img_editor_asset_library_section_audio_uploads")),
      source: .init(demoSource: .audioUpload)
    )
  }

  /// The default image asset library content.
  @AssetLibraryBuilder public static var images: AssetLibraryContent {
    AssetLibrarySource.image(
      .title(.imgly.localized("ly_img_editor_asset_library_section_images")),
      source: .init(demoSource: .image)
    )
    AssetLibrarySource.imageUpload(
      .title(.imgly.localized("ly_img_editor_asset_library_section_image_uploads")),
      source: .init(demoSource: .imageUpload)
    )
  }

  @AssetLibraryBuilder public func text(_ sceneMode: SceneMode?) -> AssetLibraryContent {
    if sceneMode == .video {
      plainText
    } else {
      textAndTextComponents
    }
  }

  let plainText = AssetLibrarySource.text(
    .title(.imgly.localized("ly_img_editor_asset_library_section_text")),
    source: .init(id: TextAssetSource.id)
  )

  @AssetLibraryBuilder public var textAndTextComponents: AssetLibraryContent {
    AssetLibrarySource.text(
      .title(.imgly.localized("ly_img_editor_asset_library_section_plain_text")),
      source: .init(id: TextAssetSource.id)
    )
    AssetLibrarySource.textComponent(
      .title(.imgly.localized("ly_img_editor_asset_library_section_font_combinations")),
      source: .init(demoSource: .textComponents)
    )
  }

  /// The default shape asset library content.
  @AssetLibraryBuilder public static var shapes: AssetLibraryContent {
    AssetLibrarySource.shape(.title(.imgly.localized("ly_img_editor_asset_library_section_basic")), source: .init(
      defaultSource: .vectorPath, config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/vectorpaths"])))
    AssetLibrarySource.shape(.title(.imgly.localized("ly_img_editor_asset_library_section_abstract")), source: .init(
      defaultSource: .vectorPath, config: .init(groups: ["//ly.img.cesdk.vectorpaths.abstract/category/abstract"])))
  }

  /// The default sticker asset library content.
  @AssetLibraryBuilder public static var stickers: AssetLibraryContent {
    AssetLibrarySource.sticker(.title(.imgly.localized("ly_img_editor_asset_library_section_doodle")), source: .init(
      defaultSource: .sticker, config: .init(groups: ["//ly.img.cesdk.stickers.doodle/category/doodle"])))
    AssetLibrarySource.sticker(.title(.imgly.localized("ly_img_editor_asset_library_section_emoji")), source: .init(
      defaultSource: .sticker, config: .init(groups: ["//ly.img.cesdk.stickers.emoji/category/emoji"])))
    AssetLibrarySource.sticker(.title(.imgly.localized("ly_img_editor_asset_library_section_emoticons")), source: .init(
      defaultSource: .sticker, config: .init(groups: ["//ly.img.cesdk.stickers.emoticons/category/emoticons"])))
    AssetLibrarySource.sticker(.title(.imgly.localized("ly_img_editor_asset_library_section_hand")), source: .init(
      defaultSource: .sticker, config: .init(groups: ["//ly.img.cesdk.stickers.hand/category/hand"])))
  }

  func tabContent(_ sceneMode: SceneMode?, _ tab: Tab) -> AssetLibraryContent {
    switch tab {
    case .elements: AssetLibraryGroup.empty
    case .uploads: uploads(sceneMode)
    case .videos: videos
    case .audio: audio
    case .images: images
    case .text: text(sceneMode)
    case .shapes: shapes
    case .stickers: stickers
    }
  }

  func elementsContent(_ sceneMode: SceneMode?, _ tab: Tab) -> AssetLibraryContent {
    switch tab {
    case .elements: AssetLibraryGroup.empty
    case .uploads: AssetLibraryGroup
      .upload(.imgly.localized("ly_img_editor_asset_library_section_uploads")) { uploads(sceneMode) }
    case .videos: AssetLibraryGroup.video(.imgly.localized("ly_img_editor_asset_library_section_videos")) { videos }
    case .audio: AssetLibraryGroup.audio(.imgly.localized("ly_img_editor_asset_library_section_audio")) { audio }
    case .images: AssetLibraryGroup.image(.imgly.localized("ly_img_editor_asset_library_section_images")) { images }
    case .text:
      if sceneMode == .video {
        plainText
      } else {
        AssetLibraryGroup.text(
          .imgly.localized("ly_img_editor_asset_library_section_text"),
          excludedPreviewSources: [Engine.DemoAssetSource.textComponents.rawValue]
        ) {
          textAndTextComponents
        }
      }
    case .shapes: AssetLibraryGroup.shape(.imgly.localized("ly_img_editor_asset_library_section_shapes")) { shapes }
    case .stickers: AssetLibraryGroup
      .sticker(.imgly.localized("ly_img_editor_asset_library_section_stickers")) { stickers }
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

  func activeTabs(_ sceneMode: SceneMode?) -> [Tab] {
    tabs.filter { tab in
      let isNotEmpty = !tabContent(sceneMode, tab).isEmpty
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

  func activeElements(_ sceneMode: SceneMode?) -> [Tab] {
    activeTabs(sceneMode).filter { $0 != .elements }
  }

  @AssetLibraryBuilder func elements(_ sceneMode: SceneMode?) -> AssetLibraryContent {
    for tab in activeElements(sceneMode) {
      elementsContent(sceneMode, tab)
    }
  }

  /// The default label for the elements tab.
  @ViewBuilder public static func elementsLabel(_ title: LocalizedStringResource) -> some View {
    Label {
      Text(title)
    } icon: {
      Image(systemName: "books.vertical")
    }
  }

  /// The default label for the uploads tab.
  @ViewBuilder public static func uploadsLabel(_ title: LocalizedStringResource) -> some View {
    Label {
      Text(title)
    } icon: {
      Image(systemName: "camera")
    }
  }

  /// The default label for the videos tab.
  @ViewBuilder public static func videosLabel(_ title: LocalizedStringResource) -> some View {
    Label {
      Text(title)
    } icon: {
      Image(systemName: "play.rectangle")
    }
  }

  /// The default label for the audio tab.
  @ViewBuilder public static func audioLabel(_ title: LocalizedStringResource) -> some View {
    Label {
      Text(title)
    } icon: {
      Image(systemName: "music.note.list")
    }
  }

  /// The default label for the images tab.
  @ViewBuilder public static func imagesLabel(_ title: LocalizedStringResource) -> some View {
    Label {
      Text(title)
    } icon: {
      Image(systemName: "photo")
    }
  }

  /// The default label for the text tab.
  @ViewBuilder public static func textLabel(_ title: LocalizedStringResource) -> some View {
    Label {
      Text(title)
    } icon: {
      Image(systemName: "textformat.alt")
    }
  }

  /// The default label for the shapes tab.
  @ViewBuilder public static func shapesLabel(_ title: LocalizedStringResource) -> some View {
    Label {
      Text(title)
    } icon: {
      Image(systemName: "square.on.circle")
    }
  }

  /// The default label for the stickers tab.
  @ViewBuilder public static func stickersLabel(_ title: LocalizedStringResource) -> some View {
    // Fixes light/dark mode fill issue with `"face.smiling"` for iOS 16.
    Label {
      Text(title)
    } icon: {
      Image("custom.face.smiling", bundle: .module)
    }
  }

  @ViewBuilder var uploadsTab: some View {
    AssetLibrarySceneModeReader { sceneMode in
      AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_uploads")) {
        uploads(sceneMode)
      } label: {
        Self.uploadsLabel($0)
      }
    }
  }

  @ViewBuilder public var elementsTab: some View {
    AssetLibrarySceneModeReader { sceneMode in
      AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_elements")) {
        elements(sceneMode)
      } label: {
        Self.elementsLabel($0)
      }
    }
  }

  @ViewBuilder public var videosTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_videos")) { videos } label: {
      Self.videosLabel($0)
    }
  }

  @ViewBuilder public var audioTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_audio")) { audio } label: {
      Self.audioLabel($0)
    }
  }

  @ViewBuilder public var imagesTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_images")) { images } label: {
      Self.imagesLabel($0)
    }
  }

  @ViewBuilder public var textTab: some View {
    AssetLibrarySceneModeReader { sceneMode in
      if sceneMode == .video {
        AssetLibraryTabView(.imgly.localized("ly_img_editor_asset_library_title_text")) {
          plainText.content
        } label: {
          Self.textLabel($0)
        }
      } else {
        AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_text")) {
          textAndTextComponents
        } label: {
          Self.textLabel($0)
        }
      }
    }
  }

  @ViewBuilder public var shapesTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_shapes")) { shapes } label: {
      Self.shapesLabel($0)
    }
  }

  @ViewBuilder public var stickersTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_stickers")) { stickers } label: {
      Self.stickersLabel($0)
    }
  }

  @ViewBuilder public var clipsTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_clips")) { videosAndImages } label: { _ in
      EmptyView()
    }
  }

  @ViewBuilder public var overlaysTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_overlays")) { videosAndImages } label: { _ in
      EmptyView()
    }
  }

  @ViewBuilder public var stickersAndShapesTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_stickers_and_shapes")) {
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
      AssetLibrarySceneModeReader { sceneMode in
        let activeTabs = activeTabs(sceneMode)
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
}

struct DefaultAssetLibrary_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
