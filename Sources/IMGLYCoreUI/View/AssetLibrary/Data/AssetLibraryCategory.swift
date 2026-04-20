import IMGLYCore
import SwiftUI

// MARK: - AssetLibraryCategory

/// A category (tab) in the asset library, containing sections.
///
/// This is the data representation of an asset library tab, aligned with Android's `AssetLibraryCategory`.
public struct AssetLibraryCategory: Sendable, Equatable {
  public let id: String
  public var title: LocalizedStringResource
  public var icon: Image
  public var sections: [AssetLibrarySection]

  /// Creates a library category.
  /// - Parameters:
  ///   - id: A unique identifier for this category.
  ///   - title: The localized title for this category.
  ///   - icon: The icon to display for this category.
  ///   - sections: The sections within this category.
  public init(
    id: String,
    title: LocalizedStringResource,
    icon: Image,
    sections: [AssetLibrarySection]
  ) {
    self.id = id
    self.title = title
    self.icon = icon
    self.sections = sections
  }

  public static func == (lhs: AssetLibraryCategory, rhs: AssetLibraryCategory) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - Category IDs

public extension AssetLibraryCategory {
  /// A namespace for default category IDs.
  enum ID {}
}

public extension AssetLibraryCategory.ID {
  /// ID for the elements category. This is a meta-category that groups all other categories.
  static let elements = "ly.img.category.elements"
  /// ID for the images category.
  static let images = "ly.img.category.images"
  /// ID for the videos category.
  static let videos = "ly.img.category.videos"
  /// ID for the audio category.
  static let audio = "ly.img.category.audio"
  /// ID for the text category.
  static let text = "ly.img.category.text"
  /// ID for the shapes category.
  static let shapes = "ly.img.category.shapes"
  /// ID for the stickers category.
  static let stickers = "ly.img.category.stickers"
  /// ID for the photo roll category.
  static let photoRoll = "ly.img.category.photoRoll"
}

// MARK: - Default Categories

public extension AssetLibraryCategory {
  /// Default images category.
  static var defaultImages: Self {
    .init(
      id: ID.images,
      title: .imgly.localized("ly_img_editor_asset_library_title_images"),
      icon: Image(systemName: "photo"),
      sections: [
        .defaultImages,
        .defaultImagesPhotoRoll,
      ],
    )
  }

  /// Default videos category.
  static var defaultVideos: Self {
    .init(
      id: ID.videos,
      title: .imgly.localized("ly_img_editor_asset_library_title_videos"),
      icon: Image(systemName: "play.rectangle"),
      sections: [
        .defaultVideos,
        .defaultVideosPhotoRoll,
      ],
    )
  }

  /// Default audio category.
  static var defaultAudio: Self {
    .init(
      id: ID.audio,
      title: .imgly.localized("ly_img_editor_asset_library_title_audio"),
      icon: Image(systemName: "music.note.list"),
      sections: [
        .defaultAudio,
        .defaultAudioUpload,
      ],
    )
  }

  /// Default text category.
  static var defaultText: Self {
    .init(
      id: ID.text,
      title: .imgly.localized("ly_img_editor_asset_library_title_text"),
      icon: Image(systemName: "textformat.alt"),
      sections: [
        .defaultText,
        .defaultTextComponents,
      ],
    )
  }

  /// Default shapes category.
  static var defaultShapes: Self {
    .init(
      id: ID.shapes,
      title: .imgly.localized("ly_img_editor_asset_library_title_shapes"),
      icon: Image(systemName: "square.on.circle"),
      sections: [
        .defaultShapesFilled,
        .defaultShapesOutline,
        .defaultShapesGradient,
        .defaultShapesImage,
        .defaultShapesAbstractFilled,
        .defaultShapesAbstractOutline,
        .defaultShapesAbstractGradient,
        .defaultShapesAbstractImage,
      ],
    )
  }

  /// Default stickers category.
  static var defaultStickers: Self {
    .init(
      id: ID.stickers,
      title: .imgly.localized("ly_img_editor_asset_library_title_stickers"),
      icon: Image("custom.face.smiling", bundle: .module),
      sections: [
        .defaultStickersEmoji,
        .defaultStickersEmoticons,
        .defaultStickersCraft,
        .defaultStickers3D,
        .defaultStickersHand,
        .defaultStickersDoodle,
      ],
    )
  }

  /// Default elements category.
  ///
  /// This is a meta-category that automatically groups all other categories into a single scrollable view.
  /// Its `sections` array is unused — the content is derived from the other categories at render time.
  static var defaultElements: Self {
    .init(
      id: ID.elements,
      title: .imgly.localized("ly_img_editor_asset_library_title_elements"),
      icon: Image(systemName: "books.vertical"),
      sections: [],
    )
  }

  /// Default photo roll category (images and videos).
  static var defaultPhotoRoll: Self {
    .init(
      id: ID.photoRoll,
      title: .imgly.localized("ly_img_editor_asset_library_title_photo_roll"),
      icon: Image(systemName: "camera"),
      sections: [
        .photoRoll(
          id: "ly.img.section.photoRoll",
          title: .imgly.localized("ly_img_editor_asset_library_section_photo_roll"),
          media: [.image, .video],
        ),
      ],
    )
  }

  /// Default categories for the asset library.
  static var defaultCategories: [Self] {
    [
      .defaultElements,
      .defaultPhotoRoll,
      .defaultVideos,
      .defaultAudio,
      .defaultImages,
      .defaultText,
      .defaultShapes,
      .defaultStickers,
    ]
  }
}
