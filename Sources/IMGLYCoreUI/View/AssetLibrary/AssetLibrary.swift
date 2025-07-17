import IMGLYEngine
import SwiftUI

/// An alias for `IMGLYEngine.SceneMode`.
@available(*, deprecated, message: "Use `IMGLYEngine.SceneMode` instead.")
public typealias AssetLibrarySceneMode = SceneMode

/// An `EnvironmentKey` for `SceneMode` used by the ``AssetLibrary``.
@_spi(Internal) public struct AssetLibrarySceneModeKey: EnvironmentKey {
  @_spi(Internal) public static let defaultValue: SceneMode? = nil
}

@_spi(Internal) public extension EnvironmentValues {
  /// The asset library scene mode.
  var imglyAssetLibrarySceneMode: AssetLibrarySceneModeKey.Value {
    get { self[AssetLibrarySceneModeKey.self] }
    set { self[AssetLibrarySceneModeKey.self] = newValue }
  }
}

/// A helper view that reads the `SceneMode` used by the ``AssetLibrary`` from the environment and provides access to
/// it.
public struct AssetLibrarySceneModeReader<Content: View>: View {
  @Environment(\.imglyAssetLibrarySceneMode) var sceneMode
  let content: (SceneMode?) -> Content

  /// Creates a helper view that reads the `SceneMode` used by the ``AssetLibrary`` from the environment  and provides
  /// access to it in a trailing `content` closure.
  /// - Parameter content: The content view.
  public init(@ViewBuilder content: @escaping (_ sceneMode: SceneMode?) -> Content) {
    self.content = content
  }

  public var body: some View {
    content(sceneMode)
  }
}

/// An interface to define an asset library.
@MainActor
public protocol AssetLibrary: View {
  associatedtype ElementsTab: View
  associatedtype VideosTab: View
  associatedtype AudioTab: View
  associatedtype ImagesTab: View
  associatedtype TextTab: View
  associatedtype ShapesTab: View
  associatedtype StickersTab: View

  /// A view to select assets used in the `DesignEditor`.
  var elementsTab: ElementsTab { get }
  /// A view to select video assets.
  var videosTab: VideosTab { get }
  /// A view to select audio assets.
  var audioTab: AudioTab { get }
  /// A view to select image assets.
  var imagesTab: ImagesTab { get }
  /// A view to select text assets.
  var textTab: TextTab { get }
  /// A view to select shape assets.
  var shapesTab: ShapesTab { get }
  /// A view to select sticker assets.
  var stickersTab: StickersTab { get }

  associatedtype ClipsTab: View
  associatedtype OverlaysTab: View
  associatedtype StickersAndShapesTab: View

  /// A view to select video and image assets used as clips in the `VideoEditor`.
  var clipsTab: ClipsTab { get }
  /// A view to select video and image assets used as overlays in the `VideoEditor`.
  var overlaysTab: OverlaysTab { get }
  /// A view to select sticker and shape assets used in the `VideoEditor`.
  var stickersAndShapesTab: StickersAndShapesTab { get }
}

public extension AssetLibrarySource<UploadGrid, AssetPreview, UploadButton> {
  /// Creates an ``AssetLibrarySource`` for image assets that supports uploads.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  /// - Returns: The created `AssetLibrarySource`.
  static func imageUpload(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) {
      Destination(media: [.image])
    } preview: {
      Preview.imageOrVideo
    } accessory: {
      Accessory(media: [.image])
    }
  }

  /// Creates an ``AssetLibrarySource`` for video assets that supports uploads.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  /// - Returns: The created `AssetLibrarySource`.
  static func videoUpload(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) {
      Destination(media: [.movie])
    } preview: {
      Preview.imageOrVideo
    } accessory: {
      Accessory(media: [.movie])
    }
  }
}

public extension AssetLibrarySource<AudioUploadGrid, AudioPreview, AudioUploadButton> {
  /// Creates an ``AssetLibrarySource`` for audio assets that supports uploads.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  /// - Returns: The created `AssetLibrarySource`.
  static func audioUpload(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) {
      Destination()
    } preview: {
      Preview()
    } accessory: {
      Accessory()
    }
  }
}

public extension AssetLibrarySource<ImageGrid<Message, EmptyView>, AssetPreview, EmptyView> {
  /// Creates an ``AssetLibrarySource`` for image assets.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  /// - Returns: The created `AssetLibrarySource`.
  static func image(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview.imageOrVideo }
  }

  /// Creates an ``AssetLibrarySource`` for video assets.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  /// - Returns: The created `AssetLibrarySource`.
  static func video(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview.imageOrVideo }
  }
}

public extension AssetLibrarySource<AudioGrid<Message, EmptyView>, AudioPreview, EmptyView> {
  /// Creates an ``AssetLibrarySource`` for audio assets.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  /// - Returns: The created `AssetLibrarySource`.
  static func audio(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview() }
  }
}

public extension AssetLibrarySource<TextGrid, TextPreview, EmptyView> {
  /// Creates an ``AssetLibrarySource`` for text assets.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  /// - Returns: The created `AssetLibrarySource`.
  static func text(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview() }
  }
}

public extension AssetLibrarySource<TextComponentGrid, AssetPreview, EmptyView> {
  /// Creates an ``AssetLibrarySource`` for text component assets.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  /// - Returns: The created `AssetLibrarySource`.
  static func textComponent(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview.imageOrVideo }
  }
}

public extension AssetLibrarySource<ShapeGrid, AssetPreview, EmptyView> {
  /// Creates an ``AssetLibrarySource`` for shape assets.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  /// - Returns: The created `AssetLibrarySource`.
  static func shape(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview.shapeOrSticker }
  }
}

public extension AssetLibrarySource<StickerGrid, AssetPreview, EmptyView> {
  /// Creates an ``AssetLibrarySource`` for sticker assets.
  /// - Parameters:
  ///   - mode: The display mode which defines the section title(s).
  ///   - source: The asset source definition.
  /// - Returns: The created `AssetLibrarySource`.
  static func sticker(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview.shapeOrSticker }
  }
}

public extension AssetLibraryGroup<AssetPreview> {
  /// Creates an ``AssetLibraryGroup`` for asset sources that support uploads.
  /// - Parameters:
  ///   - title: The displayed name of the group.
  ///   - content: The asset library content.
  /// - Returns: The created `AssetLibraryGroup`.
  static func upload(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview.imageOrVideo }
  }

  /// Creates an ``AssetLibraryGroup`` for image assets.
  /// - Parameters:
  ///   - title: The displayed name of the group.
  ///   - content: The asset library content.
  /// - Returns: The created `AssetLibraryGroup`.
  static func image(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview.imageOrVideo }
  }

  /// Creates an ``AssetLibraryGroup`` for video assets.
  /// - Parameters:
  ///   - title: The displayed name of the group.
  ///   - content: The asset library content.
  /// - Returns: The created `AssetLibraryGroup`.
  static func video(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview.imageOrVideo }
  }

  /// Creates an ``AssetLibraryGroup`` for shape assets.
  /// - Parameters:
  ///   - title: The displayed name of the group.
  ///   - content: The asset library content.
  /// - Returns: The created `AssetLibraryGroup`.
  static func shape(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview.shapeOrSticker }
  }

  /// Creates an ``AssetLibraryGroup`` for sticker assets.
  /// - Parameters:
  ///   - title: The displayed name of the group.
  ///   - content: The asset library content.
  /// - Returns: The created `AssetLibraryGroup`.
  static func sticker(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview.shapeOrSticker }
  }
}

public extension AssetLibraryGroup<AudioPreview> {
  /// Creates an ``AssetLibraryGroup`` for audio assets.
  /// - Parameters:
  ///   - title: The displayed name of the group.
  ///   - content: The asset library content.
  /// - Returns: The created `AssetLibraryGroup`.
  static func audio(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview() }
  }
}

public extension AssetLibraryGroup<TextPreview> {
  /// Creates an ``AssetLibraryGroup`` for text assets.
  /// - Parameters:
  ///   - title: The displayed name of the group.
  ///   - excludedPreviewSources: Asset source IDs whose assets should not be displayed in the preview.
  ///   - content: The asset library content.
  /// - Returns: The created `AssetLibraryGroup`.
  static func text(
    _ title: String,
    excludedPreviewSources: Set<String> = [],
    @AssetLibraryBuilder content: () -> AssetLibraryContent
  ) -> Self {
    self.init(title, excludedPreviewSources: excludedPreviewSources, content: content) { Preview() }
  }
}

public extension AssetLibraryGroup<EmptyView> {
  /// An empty ``AssetLibraryGroup``.
  static var empty: Self {
    self.init(components: [])
  }
}

@MainActor
public extension AssetPreview {
  /// An ``AssetPreview`` for image, video, or text component assets.
  static let imageOrVideo = Self(height: 96)
  /// An ``AssetPreview`` for shape or sticker assets.
  static let shapeOrSticker = Self(height: 80)
}

struct AssetLibrary_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
