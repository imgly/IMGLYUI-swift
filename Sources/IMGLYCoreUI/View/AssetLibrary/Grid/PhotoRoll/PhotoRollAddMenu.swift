@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI
import UIKit

struct PhotoRollAddMenu<Label: View>: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  @State private var showCamera = false
  @State private var showLimitedLibraryPicker = false

  private let media: [PhotoRollMediaType]
  @ViewBuilder private let label: () -> Label

  init(media: [PhotoRollMediaType], @ViewBuilder label: @escaping () -> Label) {
    self.media = media
    self.label = label
  }

  private var titleForCamera: String.LocalizationValue {
    if media.contains(.image), media.contains(.video) {
      "ly_img_editor_asset_library_button_take_photo_or_video"
    } else if media.contains(.image) {
      "ly_img_editor_asset_library_button_take_photo"
    } else {
      "ly_img_editor_asset_library_button_take_video"
    }
  }

  private var mediaCompletion: MediaCompletion {
    { result in
      Task {
        let results = try result.get()
        guard let (url, mediaType) = results.first else { return }

        let assetResult = try await PhotoRollAssetService.default.saveMediaAndConvert(
          url: url,
          mediaType: mediaType.photoRollMediaType.phAssetMediaType,
        )

        interactor.assetTapped(sourceID: PhotoRollAssetSource.id, asset: assetResult)
      }
    }
  }

  var body: some View {
    Menu {
      if PhotoLibraryAuthorizationManager.shared.authorizationStatus == .limited {
        Button {
          showLimitedLibraryPicker.toggle()
        } label: {
          SwiftUI.Label {
            Text(.imgly.localized("ly_img_editor_asset_library_button_select_more_photos"))
          } icon: {
            Image(systemName: "photo.badge.plus")
          }
        }

        Button {
          AppSettingsHelper.openAppSettings()
        } label: {
          SwiftUI.Label {
            Text(.imgly.localized("ly_img_editor_asset_library_button_change_permissions"))
          } icon: {
            Image(systemName: "switch.2")
          }
        }
      }

      Button {
        showCamera.toggle()
      } label: {
        SwiftUI.Label {
          Text(.imgly.localized(titleForCamera))
        } icon: {
          Image(systemName: "camera")
        }
      }
    } label: {
      label()
    }
    .imgly.camera(isPresented: $showCamera, media: media.map(\.mediaType), onComplete: mediaCompletion)
    .imgly.limitedLibraryPicker(isPresented: $showLimitedLibraryPicker, onComplete: PhotoRollAssetSource.refreshAssets)
  }
}

extension MediaType {
  var photoRollMediaType: PhotoRollMediaType {
    switch self {
    case .image: .image
    case .movie: .video
    }
  }
}

extension PhotoRollMediaType {
  var mediaType: MediaType {
    switch self {
    case .image: .image
    case .video: .movie
    }
  }
}
