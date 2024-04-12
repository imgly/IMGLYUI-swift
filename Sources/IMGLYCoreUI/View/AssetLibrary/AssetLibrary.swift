import IMGLYEngine
import SwiftUI

public typealias AssetLibrarySceneMode = SceneMode

public struct AssetLibrarySceneModeKey: EnvironmentKey {
  @_spi(Internal) public static let defaultValue: AssetLibrarySceneMode? = nil
}

public extension EnvironmentValues {
  var imglyAssetLibrarySceneMode: AssetLibrarySceneModeKey.Value {
    get { self[AssetLibrarySceneModeKey.self] }
    set { self[AssetLibrarySceneModeKey.self] = newValue }
  }
}

@MainActor
public protocol AssetLibrary: View {
  associatedtype VideosTab: View
  associatedtype AudioTab: View
  associatedtype ImagesTab: View
  associatedtype TextTab: View
  associatedtype ShapesTab: View
  associatedtype StickersTab: View

  var videosTab: VideosTab { get }
  var audioTab: AudioTab { get }
  var imagesTab: ImagesTab { get }
  var textTab: TextTab { get }
  var shapesTab: ShapesTab { get }
  var stickersTab: StickersTab { get }

  associatedtype ClipsTab: View
  associatedtype OverlaysTab: View
  associatedtype StickersAndShapesTab: View

  var clipsTab: ClipsTab { get }
  var overlaysTab: OverlaysTab { get }
  var stickersAndShapesTab: StickersAndShapesTab { get }
}

public extension AssetLibrarySource<UploadGrid, AssetPreview, UploadButton> {
  static func imageUpload(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) {
      Destination(media: [.image])
    } preview: {
      Preview.imageOrVideo
    } accessory: {
      Accessory(media: [.image])
    }
  }

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
  static func image(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview.imageOrVideo }
  }

  static func video(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview.imageOrVideo }
  }
}

public extension AssetLibrarySource<AudioGrid<Message, EmptyView>, AudioPreview, EmptyView> {
  static func audio(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview() }
  }
}

public extension AssetLibrarySource<TextGrid, TextPreview, EmptyView> {
  static func text(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview() }
  }
}

public extension AssetLibrarySource<ShapeGrid, AssetPreview, EmptyView> {
  static func shape(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview.shapeOrSticker }
  }
}

public extension AssetLibrarySource<StickerGrid, AssetPreview, EmptyView> {
  static func sticker(_ mode: Mode, source: AssetLoader.SourceData) -> Self {
    self.init(mode, source: source) { Destination() } preview: { Preview.shapeOrSticker }
  }
}

public extension AssetLibraryGroup<AssetPreview> {
  static func upload(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview.imageOrVideo }
  }

  static func image(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview.imageOrVideo }
  }

  static func video(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview.imageOrVideo }
  }

  static func shape(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview.shapeOrSticker }
  }

  static func sticker(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview.shapeOrSticker }
  }
}

public extension AssetLibraryGroup<AudioPreview> {
  static func audio(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview() }
  }
}

public extension AssetLibraryGroup<TextPreview> {
  static func text(_ title: String, @AssetLibraryBuilder content: () -> AssetLibraryContent) -> Self {
    self.init(title, content: content) { Preview() }
  }
}

public extension AssetLibraryGroup<EmptyView> {
  static var empty: Self {
    self.init(components: [])
  }
}

@MainActor
public extension AssetPreview {
  static let imageOrVideo = Self(height: 96)
  static let shapeOrSticker = Self(height: 80)
}

struct AssetLibrary_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
