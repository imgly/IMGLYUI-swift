import IMGLYCore
import IMGLYEngine
import SwiftUI

// MARK: - AssetLibrarySection

/// A section within a library category, representing an asset source.
///
/// This is the data representation of an asset section, aligned with Android's `LibraryContent.Section`.
public struct AssetLibrarySection: Sendable, Equatable {
  public let id: String
  public let title: LocalizedStringResource?
  public let source: AssetLoader.SourceData

  /// The type of content this section displays.
  public let contentType: ContentType

  /// The content type determines how the section is rendered.
  public enum ContentType: Sendable, Equatable {
    case image
    case imageUpload
    case video
    case videoUpload
    case audio
    case audioUpload
    case text
    case textComponent
    case shape
    case sticker
    case photoRoll(media: [PhotoRollMediaType])
  }

  /// Creates a library section.
  /// - Parameters:
  ///   - id: A unique identifier for this section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  ///   - contentType: The type of content this section displays.
  public init(
    id: String,
    title: LocalizedStringResource?,
    source: AssetLoader.SourceData,
    contentType: ContentType
  ) {
    self.id = id
    self.title = title
    self.source = source
    self.contentType = contentType
  }

  public static func == (lhs: AssetLibrarySection, rhs: AssetLibrarySection) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - Default Section IDs

@_spi(Internal) public extension AssetLibrarySection {
  /// A namespace for default section IDs.
  ///
  /// These IDs are tied to specific default asset packs and may change between versions.
  enum ID {}
}

@_spi(Internal) public extension AssetLibrarySection.ID {
  // MARK: Images

  /// ID for the default images section.
  static let images = "ly.img.section.images"
  /// ID for the images photo roll section.
  static let imagesPhotoRoll = "ly.img.section.images.photoRoll"

  // MARK: Videos

  /// ID for the default videos section.
  static let videos = "ly.img.section.videos"
  /// ID for the videos photo roll section.
  static let videosPhotoRoll = "ly.img.section.videos.photoRoll"

  // MARK: Audio

  /// ID for the default audio section.
  static let audio = "ly.img.section.audio"
  /// ID for the audio upload section.
  static let audioUpload = "ly.img.section.audio.upload"

  // MARK: Text

  /// ID for the default text section.
  static let text = "ly.img.section.text"
  /// ID for the text components section.
  static let textComponents = "ly.img.section.text.components"

  // MARK: Shapes

  /// ID for filled shapes section.
  static let shapesFilled = "ly.img.section.shapes.filled"
  /// ID for outline shapes section.
  static let shapesOutline = "ly.img.section.shapes.outline"
  /// ID for gradient shapes section.
  static let shapesGradient = "ly.img.section.shapes.gradient"
  /// ID for image shapes section.
  static let shapesImage = "ly.img.section.shapes.image"
  /// ID for abstract filled shapes section.
  static let shapesAbstractFilled = "ly.img.section.shapes.abstractFilled"
  /// ID for abstract outline shapes section.
  static let shapesAbstractOutline = "ly.img.section.shapes.abstractOutline"
  /// ID for abstract gradient shapes section.
  static let shapesAbstractGradient = "ly.img.section.shapes.abstractGradient"
  /// ID for abstract image shapes section.
  static let shapesAbstractImage = "ly.img.section.shapes.abstractImage"

  // MARK: Stickers

  /// ID for emoji stickers section.
  static let stickersEmoji = "ly.img.section.stickers.emoji"
  /// ID for emoticons stickers section.
  static let stickersEmoticons = "ly.img.section.stickers.emoticons"
  /// ID for craft stickers section.
  static let stickersCraft = "ly.img.section.stickers.craft"
  /// ID for 3D stickers section.
  static let stickers3D = "ly.img.section.stickers.3d"
  /// ID for hand stickers section.
  static let stickersHand = "ly.img.section.stickers.hand"
  /// ID for doodle stickers section.
  static let stickersDoodle = "ly.img.section.stickers.doodle"
}

// MARK: - Factory Methods

public extension AssetLibrarySection {
  /// Creates an image section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  static func image(
    id: String,
    title: LocalizedStringResource,
    source: AssetLoader.SourceData,
  ) -> Self {
    .init(id: id, title: title, source: source, contentType: .image)
  }

  /// Creates an image upload section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  static func imageUpload(
    id: String,
    title: LocalizedStringResource,
    source: AssetLoader.SourceData,
  ) -> Self {
    .init(id: id, title: title, source: source, contentType: .imageUpload)
  }

  /// Creates a video section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  static func video(
    id: String,
    title: LocalizedStringResource,
    source: AssetLoader.SourceData,
  ) -> Self {
    .init(id: id, title: title, source: source, contentType: .video)
  }

  /// Creates a video upload section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  static func videoUpload(
    id: String,
    title: LocalizedStringResource,
    source: AssetLoader.SourceData,
  ) -> Self {
    .init(id: id, title: title, source: source, contentType: .videoUpload)
  }

  /// Creates an audio section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  static func audio(
    id: String,
    title: LocalizedStringResource,
    source: AssetLoader.SourceData,
  ) -> Self {
    .init(id: id, title: title, source: source, contentType: .audio)
  }

  /// Creates an audio upload section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  static func audioUpload(
    id: String,
    title: LocalizedStringResource,
    source: AssetLoader.SourceData,
  ) -> Self {
    .init(id: id, title: title, source: source, contentType: .audioUpload)
  }

  /// Creates a text section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  static func text(
    id: String,
    title: LocalizedStringResource,
    source: AssetLoader.SourceData,
  ) -> Self {
    .init(id: id, title: title, source: source, contentType: .text)
  }

  /// Creates a text component section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  static func textComponent(
    id: String,
    title: LocalizedStringResource,
    source: AssetLoader.SourceData,
  ) -> Self {
    .init(id: id, title: title, source: source, contentType: .textComponent)
  }

  /// Creates a shape section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  static func shape(
    id: String,
    title: LocalizedStringResource,
    source: AssetLoader.SourceData,
  ) -> Self {
    .init(id: id, title: title, source: source, contentType: .shape)
  }

  /// Creates a sticker section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - source: The asset source data.
  static func sticker(
    id: String,
    title: LocalizedStringResource,
    source: AssetLoader.SourceData,
  ) -> Self {
    .init(id: id, title: title, source: source, contentType: .sticker)
  }

  /// Creates a photo roll section.
  /// - Parameters:
  ///   - id: A unique identifier for this section. Provide a unique, stable identifier for your section.
  ///   - title: The localized title for this section.
  ///   - media: The media types to include (images, videos, or both).
  static func photoRoll(
    id: String,
    title: LocalizedStringResource,
    media: [PhotoRollMediaType],
  ) -> Self {
    .init(
      id: id,
      title: title,
      source: .init(id: PhotoRollAssetSource.id, config: .init(groups: media.map(\.rawValue))),
      contentType: .photoRoll(media: media),
    )
  }
}

// MARK: - Default Sections

/// Default sections used by category defaults.
///
/// These sections are tied to specific default asset packs and may change between versions.
/// Use `@_spi(Internal) import IMGLYCoreUI` to access them.
@_spi(Internal) public extension AssetLibrarySection {
  // MARK: Images

  static var defaultImages: Self {
    .image(
      id: ID.images,
      title: .imgly.localized("ly_img_editor_asset_library_section_images"),
      source: .init(demoSource: .image),
    )
  }

  static var defaultImagesPhotoRoll: Self {
    .photoRoll(
      id: ID.imagesPhotoRoll,
      title: .imgly.localized("ly_img_editor_asset_library_section_photo_roll"),
      media: [.image],
    )
  }

  // MARK: Videos

  static var defaultVideos: Self {
    .video(
      id: ID.videos,
      title: .imgly.localized("ly_img_editor_asset_library_section_videos"),
      source: .init(demoSource: .video),
    )
  }

  static var defaultVideosPhotoRoll: Self {
    .photoRoll(
      id: ID.videosPhotoRoll,
      title: .imgly.localized("ly_img_editor_asset_library_section_photo_roll"),
      media: [.video],
    )
  }

  // MARK: Audio

  static var defaultAudio: Self {
    .audio(
      id: ID.audio,
      title: .imgly.localized("ly_img_editor_asset_library_section_audio"),
      source: .init(demoSource: .audio),
    )
  }

  static var defaultAudioUpload: Self {
    .audioUpload(
      id: ID.audioUpload,
      title: .imgly.localized("ly_img_editor_asset_library_section_audio_uploads"),
      source: .init(demoSource: .audioUpload),
    )
  }

  // MARK: Text

  static var defaultText: Self {
    .text(
      id: ID.text,
      title: .imgly.localized("ly_img_editor_asset_library_section_plain_text"),
      source: .init(id: TextAssetSource.id),
    )
  }

  static var defaultTextComponents: Self {
    .textComponent(
      id: ID.textComponents,
      title: .imgly.localized("ly_img_editor_asset_library_section_font_combinations"),
      source: .init(demoSource: .textComponents),
    )
  }

  // MARK: Shapes

  static var defaultShapesFilled: Self {
    .shape(
      id: ID.shapesFilled,
      title: .imgly.localized("ly_img_editor_asset_library_section_filled"),
      source: .init(
        defaultSource: .vectorPath,
        config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/filled"]),
      ),
    )
  }

  static var defaultShapesOutline: Self {
    .shape(
      id: ID.shapesOutline,
      title: .imgly.localized("ly_img_editor_asset_library_section_outline"),
      source: .init(
        defaultSource: .vectorPath,
        config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/outline"]),
      ),
    )
  }

  static var defaultShapesGradient: Self {
    .shape(
      id: ID.shapesGradient,
      title: .imgly.localized("ly_img_editor_asset_library_section_gradient"),
      source: .init(
        defaultSource: .vectorPath,
        config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/gradient"]),
      ),
    )
  }

  static var defaultShapesImage: Self {
    .shape(
      id: ID.shapesImage,
      title: .imgly.localized("ly_img_editor_asset_library_section_image"),
      source: .init(
        defaultSource: .vectorPath,
        config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/image"]),
      ),
    )
  }

  static var defaultShapesAbstractFilled: Self {
    .shape(
      id: ID.shapesAbstractFilled,
      title: .imgly.localized("ly_img_editor_asset_library_section_abstract_filled"),
      source: .init(
        defaultSource: .vectorPath,
        config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/abstract-filled"]),
      ),
    )
  }

  static var defaultShapesAbstractOutline: Self {
    .shape(
      id: ID.shapesAbstractOutline,
      title: .imgly.localized("ly_img_editor_asset_library_section_abstract_outline"),
      source: .init(
        defaultSource: .vectorPath,
        config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/abstract-outline"]),
      ),
    )
  }

  static var defaultShapesAbstractGradient: Self {
    .shape(
      id: ID.shapesAbstractGradient,
      title: .imgly.localized("ly_img_editor_asset_library_section_abstract_gradient"),
      source: .init(
        defaultSource: .vectorPath,
        config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/abstract-gradient"]),
      ),
    )
  }

  static var defaultShapesAbstractImage: Self {
    .shape(
      id: ID.shapesAbstractImage,
      title: .imgly.localized("ly_img_editor_asset_library_section_abstract_image"),
      source: .init(
        defaultSource: .vectorPath,
        config: .init(groups: ["//ly.img.cesdk.vectorpaths/category/abstract-image"]),
      ),
    )
  }

  // MARK: Stickers

  static var defaultStickersEmoji: Self {
    .sticker(
      id: ID.stickersEmoji,
      title: .imgly.localized("ly_img_editor_asset_library_section_emoji"),
      source: .init(
        defaultSource: .sticker,
        config: .init(groups: ["//ly.img.cesdk.stickers.emoji/category/emoji"]),
      ),
    )
  }

  static var defaultStickersEmoticons: Self {
    .sticker(
      id: ID.stickersEmoticons,
      title: .imgly.localized("ly_img_editor_asset_library_section_emoticons"),
      source: .init(
        defaultSource: .sticker,
        config: .init(groups: ["//ly.img.cesdk.stickers.emoticons/category/emoticons"]),
      ),
    )
  }

  static var defaultStickersCraft: Self {
    .sticker(
      id: ID.stickersCraft,
      title: .imgly.localized("ly_img_editor_asset_library_section_craft"),
      source: .init(
        defaultSource: .sticker,
        config: .init(groups: ["//ly.img.cesdk.stickers.craft/category/craft"]),
      ),
    )
  }

  static var defaultStickers3D: Self {
    .sticker(
      id: ID.stickers3D,
      title: .imgly.localized("ly_img_editor_asset_library_section_3d_stickers"),
      source: .init(
        defaultSource: .sticker,
        config: .init(groups: ["//ly.img.cesdk.stickers.3Dstickers/category/3Dstickers"]),
      ),
    )
  }

  static var defaultStickersHand: Self {
    .sticker(
      id: ID.stickersHand,
      title: .imgly.localized("ly_img_editor_asset_library_section_hand"),
      source: .init(
        defaultSource: .sticker,
        config: .init(groups: ["//ly.img.cesdk.stickers.hand/category/hand"]),
      ),
    )
  }

  static var defaultStickersDoodle: Self {
    .sticker(
      id: ID.stickersDoodle,
      title: .imgly.localized("ly_img_editor_asset_library_section_doodle"),
      source: .init(
        defaultSource: .sticker,
        config: .init(groups: ["//ly.img.cesdk.stickers.doodle/category/doodle"]),
      ),
    )
  }
}
