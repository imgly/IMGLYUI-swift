@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

@_spi(Internal) public struct UploadMenu<Label: View>: View {
  @Environment(\.imglyAssetLibrarySources) private var sources
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  private let media: [MediaType]

  @State private var showImagePicker = false
  @State private var showCamera = false
  @State private var showFileImporter = false

  @ViewBuilder private let label: () -> Label

  @Feature(.photosPickerMultiSelect) private var isPhotosPickerMultiSelectEnabled: Bool

  @_spi(Internal) public init(media: [MediaType], @ViewBuilder label: @escaping () -> Label) {
    self.media = media
    self.label = label
  }

  var mediaCompletion: MediaCompletion {
    { result in
      guard let source = sources.first else {
        return
      }
      Task {
        for (url, media) in try result.get() {
          _ = try await interactor.uploadAsset(to: source.id) {
            switch media {
            case .image: .init(url: url, blockType: .graphic, blockKind: .key(.image), fillType: .image)
            case .movie: .init(url: url, blockType: .graphic, blockKind: .key(.video), fillType: .video)
            }
          }
        }
      }
    }
  }

  private var maxSelectionCount: Int? {
    isPhotosPickerMultiSelectEnabled ? nil : 1
  }

  private enum Action {
    case choose, take, select
  }

  // swiftlint:disable:next cyclomatic_complexity
  private func title(for action: Action) -> String.LocalizationValue {
    if media.contains(.image), media.contains(.movie) {
      switch action {
      case .choose: "ly_img_editor_asset_library_button_choose_photo_or_video"
      case .take: "ly_img_editor_asset_library_button_take_photo_or_video"
      case .select: "ly_img_editor_asset_library_button_select_photo_or_video"
      }
    } else if media.contains(.image) {
      switch action {
      case .choose: "ly_img_editor_asset_library_button_choose_photo"
      case .take: "ly_img_editor_asset_library_button_take_photo"
      case .select: "ly_img_editor_asset_library_button_select_photo"
      }
    } else {
      switch action {
      case .choose: "ly_img_editor_asset_library_button_choose_video"
      case .take: "ly_img_editor_asset_library_button_take_video"
      case .select: "ly_img_editor_asset_library_button_select_video"
      }
    }
  }

  @_spi(Internal) public var body: some View {
    Menu {
      Button {
        showImagePicker.toggle()
      } label: {
        SwiftUI.Label {
          Text(.imgly.localized(title(for: .choose)))
        } icon: {
          Image(systemName: "photo.on.rectangle")
        }
      }
      Button {
        showCamera.toggle()
      } label: {
        SwiftUI.Label {
          Text(.imgly.localized(title(for: .take)))
        } icon: {
          Image(systemName: "camera")
        }
      }
      Button {
        showFileImporter.toggle()
      } label: {
        SwiftUI.Label {
          Text(.imgly.localized(title(for: .select)))
        } icon: {
          Image(systemName: "folder")
        }
      }
    } label: {
      label()
    }
    .imgly.photoRoll(
      isPresented: $showImagePicker,
      media: media,
      maxSelectionCount: maxSelectionCount,
      onComplete: mediaCompletion,
    )
    .imgly.camera(isPresented: $showCamera, media: media, onComplete: mediaCompletion)
    .imgly.assetFileUploader(isPresented: $showFileImporter, allowedContentTypes: media.map(\.contentType))
  }
}

struct UploadMenu_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
