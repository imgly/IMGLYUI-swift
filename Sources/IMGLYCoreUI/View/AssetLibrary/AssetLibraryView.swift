@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

/// An asset library view that renders content from `AssetLibraryCategory` data.
///
/// This is the default `AssetLibrary` implementation used by the editor.
@MainActor
public struct AssetLibraryView: AssetLibrary {
  private let categories: [AssetLibraryCategory]
  private let includeAVResources: Bool

  /// Creates an asset library from category data.
  /// - Parameters:
  ///   - categories: The categories to render.
  ///   - includeAVResources: Whether video and audio resources are included. Defaults to `false`.
  public init(categories: [AssetLibraryCategory], includeAVResources: Bool = false) {
    self.categories = categories
    self.includeAVResources = includeAVResources
  }

  // MARK: - Body

  /// Categories rendered as groups inside the elements tab.
  ///
  /// Excludes `elements` (the meta-category itself); all other categories (including `photoRoll`)
  /// are rendered via ``elementGroup(for:)``.
  private var contentCategories: [AssetLibraryCategory] {
    categories.filter { $0.id != AssetLibraryCategory.ID.elements }
  }

  /// The categories that are actually rendered as tabs after filtering:
  /// - `elements` is always kept (its content is derived from the other categories).
  /// - `videos`/`audio` are only kept when `includeAVResources` is `true` and they are non-empty.
  /// - All other categories are kept when they are non-empty.
  private var activeCategories: [AssetLibraryCategory] {
    categories.filter { category in
      switch category.id {
      case AssetLibraryCategory.ID.elements:
        true
      case AssetLibraryCategory.ID.videos, AssetLibraryCategory.ID.audio:
        includeAVResources && !category.sections.isEmpty
      default:
        !category.sections.isEmpty
      }
    }
  }

  public var body: some View {
    TabView {
      let active = activeCategories
      if active.count > 5 {
        let hasElements = active.contains { $0.id == AssetLibraryCategory.ID.elements }
        let hasPhotoRoll = active.contains { $0.id == AssetLibraryCategory.ID.photoRoll }
        if hasElements, hasPhotoRoll, active.count == 6 {
          // `elementsTab` already surfaces the photo roll at the top, so we drop the
          // dedicated photo roll tab here to keep the five-tab layout.
          let withoutPhotoRoll = active.filter { $0.id != AssetLibraryCategory.ID.photoRoll }
          tabViews(for: withoutPhotoRoll)
        } else {
          let primary = active.prefix(4)
          let overflow = active.dropFirst(4)
          tabViews(for: primary)
          AssetLibraryMoreTab {
            tabViews(for: overflow)
          }
        }
      } else {
        tabViews(for: active)
      }
    }
  }

  @ViewBuilder
  private func tabViews(for categories: some RandomAccessCollection<AssetLibraryCategory>) -> some View {
    ForEach(categories, id: \.id) { category in
      if category.id == AssetLibraryCategory.ID.elements {
        elementsTab
      } else {
        tabView(for: category)
      }
    }
  }

  // MARK: - Required Tabs (AssetLibrary Protocol)

  @ViewBuilder public var elementsTab: some View {
    let elementsCategory = category(for: AssetLibraryCategory.ID.elements)
    let title = elementsCategory?.title ?? .imgly.localized("ly_img_editor_asset_library_title_elements")
    let icon = elementsCategory?.icon ?? Image(systemName: "books.vertical")
    // Elements tab combines all other categories into a grouped view
    AssetLibraryTab(title) {
      elementsContent
    } label: { tabTitle in
      Label {
        Text(tabTitle)
      } icon: {
        icon
      }
    }
  }

  @ViewBuilder public var videosTab: some View {
    if let category = category(for: AssetLibraryCategory.ID.videos) {
      tabView(for: category)
    } else {
      EmptyView()
    }
  }

  @ViewBuilder public var audioTab: some View {
    if let category = category(for: AssetLibraryCategory.ID.audio) {
      tabView(for: category)
    } else {
      EmptyView()
    }
  }

  @ViewBuilder public var imagesTab: some View {
    if let category = category(for: AssetLibraryCategory.ID.images) {
      tabView(for: category)
    } else {
      EmptyView()
    }
  }

  @ViewBuilder public var textTab: some View {
    if let category = category(for: AssetLibraryCategory.ID.text) {
      tabView(for: category)
    } else {
      EmptyView()
    }
  }

  @ViewBuilder public var shapesTab: some View {
    if let category = category(for: AssetLibraryCategory.ID.shapes) {
      tabView(for: category)
    } else {
      EmptyView()
    }
  }

  @ViewBuilder public var stickersTab: some View {
    if let category = category(for: AssetLibraryCategory.ID.stickers) {
      tabView(for: category)
    } else {
      EmptyView()
    }
  }

  @ViewBuilder public var photoRollTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_photo_roll")) {
      AssetLibrarySource.photoRoll(
        .title(.imgly.localized("ly_img_editor_asset_library_section_photo_roll")),
        media: includeAVResources ? [.image, .video] : [.image],
      )
    } label: { _ in
      EmptyView()
    }
  }

  @ViewBuilder public var clipsTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_clips")) {
      videosAndImagesContent
    } label: { _ in
      EmptyView()
    }
  }

  @ViewBuilder public var overlaysTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_overlays")) {
      videosAndImagesContent
    } label: { _ in
      EmptyView()
    }
  }

  @ViewBuilder public var stickersAndShapesTab: some View {
    AssetLibraryTab(.imgly.localized("ly_img_editor_asset_library_title_stickers_and_shapes")) {
      stickersAndShapesContent
    } label: { _ in
      EmptyView()
    }
  }

  // MARK: - Private

  private func category(for id: String) -> AssetLibraryCategory? {
    categories.first { $0.id == id }
  }

  @ViewBuilder
  private func tabView(for category: AssetLibraryCategory) -> some View {
    AssetLibraryTab(category.title) {
      sectionsContent(for: category)
    } label: { _ in
      Label {
        Text(category.title)
      } icon: {
        category.icon
      }
    }
  }

  @AssetLibraryBuilder
  private func sectionsContent(for category: AssetLibraryCategory) -> AssetLibraryContent {
    for section in category.sections {
      sectionContent(for: section)
    }
  }

  @AssetLibraryBuilder
  private var elementsContent: AssetLibraryContent {
    for category in contentCategories {
      elementGroup(for: category)
    }
  }

  private func elementGroup(for category: AssetLibraryCategory) -> AssetLibraryContent {
    switch category.id {
    case AssetLibraryCategory.ID.photoRoll:
      return sectionsContent(for: category)
    case AssetLibraryCategory.ID.text:
      let textComponentSourceIDs = Set(
        category.sections
          .filter { $0.contentType == .textComponent }
          .map(\.source.id),
      )
      return AssetLibraryGroup.text(
        category.title,
        excludedPreviewSources: textComponentSourceIDs,
      ) {
        sectionsContent(for: category)
      }
    case AssetLibraryCategory.ID.shapes:
      return AssetLibraryGroup.shape(category.title) {
        sectionsContent(for: category)
      }
    case AssetLibraryCategory.ID.stickers:
      return AssetLibraryGroup.sticker(category.title) {
        sectionsContent(for: category)
      }
    case AssetLibraryCategory.ID.audio:
      return AssetLibraryGroup.audio(category.title) {
        sectionsContent(for: category)
      }
    default:
      return AssetLibraryGroup(category.title) {
        sectionsContent(for: category)
      } preview: {
        AssetPreview.imageOrVideo
      }
    }
  }

  @AssetLibraryBuilder
  private var videosAndImagesContent: AssetLibraryContent {
    if let videos = category(for: AssetLibraryCategory.ID.videos) {
      AssetLibraryGroup.video(.imgly.localized("ly_img_editor_asset_library_section_videos")) {
        sectionsContent(for: videos)
      }
    }
    if let images = category(for: AssetLibraryCategory.ID.images) {
      AssetLibraryGroup.image(.imgly.localized("ly_img_editor_asset_library_section_images")) {
        sectionsContent(for: images)
      }
    }
    AssetLibrarySource.photoRoll(
      .title(.imgly.localized("ly_img_editor_asset_library_section_photo_roll")),
      media: [.image, .video],
    )
  }

  @AssetLibraryBuilder
  private var stickersAndShapesContent: AssetLibraryContent {
    if let stickers = category(for: AssetLibraryCategory.ID.stickers) {
      sectionsContent(for: stickers)
    }
    if let shapes = category(for: AssetLibraryCategory.ID.shapes) {
      sectionsContent(for: shapes)
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  private func sectionContent(for section: AssetLibrarySection) -> AssetLibraryContent {
    let title = section.title ?? ""
    switch section.contentType {
    case .image:
      return AssetLibrarySource.image(.title(title), source: section.source)

    case .imageUpload:
      return AssetLibrarySource.imageUpload(.title(title), source: section.source)

    case .video:
      return AssetLibrarySource.video(.title(title), source: section.source)

    case .videoUpload:
      return AssetLibrarySource.videoUpload(.title(title), source: section.source)

    case .audio:
      return AssetLibrarySource.audio(.title(title), source: section.source)

    case .audioUpload:
      return AssetLibrarySource.audioUpload(.title(title), source: section.source)

    case .text:
      return AssetLibrarySource.text(.title(title), source: section.source)

    case .textComponent:
      return AssetLibrarySource.textComponent(.title(title), source: section.source)

    case .shape:
      return AssetLibrarySource.shape(.title(title), source: section.source)

    case .sticker:
      return AssetLibrarySource.sticker(.title(title), source: section.source)

    case let .photoRoll(media):
      // When AV resources are disabled (e.g. in a photo editor), constrain photo roll to images only.
      let effectiveMedia = includeAVResources ? media : media.filter { $0 != .video }
      return AssetLibrarySource.photoRoll(.title(title), media: effectiveMedia)
    }
  }
}
