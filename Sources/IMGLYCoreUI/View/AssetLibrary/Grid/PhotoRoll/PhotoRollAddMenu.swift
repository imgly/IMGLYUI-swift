@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI
import UIKit

struct PhotoRollAddMenu<Label: View>: View {
  @Environment(\.imglyAssetLibrarySources) private var sources
  @Environment(\.imglyAssetLibrarySceneMode) private var sceneMode
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  @State private var showCamera = false
  @State private var showLimitedLibraryPicker = false

  @ViewBuilder private let label: () -> Label

  init(label: @escaping () -> Label) {
    self.label = label
  }

  private var media: [MediaType] {
    if sceneMode == .video {
      [.image, .movie]
    } else {
      [.image]
    }
  }

  private var titleForCamera: String.LocalizationValue {
    if sceneMode == .video {
      "ly_img_editor_asset_library_button_take_photo_or_video"
    } else {
      "ly_img_editor_asset_library_button_take_photo"
    }
  }

  private var mediaCompletion: MediaCompletion {
    { result in
      guard let source = sources.first else { return }

      Task {
        let results = try result.get()
        guard let (url, mediaType) = results.first else { return }

        let assetResult = try await PhotoRollAssetService.default.saveMediaAndConvert(
          url: url,
          mediaType: mediaType == .image ? .image : .video,
          sourceID: source.id,
        )

        interactor.assetTapped(sourceID: source.id, asset: assetResult)
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
    .imgly.camera(isPresented: $showCamera, media: media, onComplete: mediaCompletion)
    .imgly.limitedLibraryPicker(isPresented: $showLimitedLibraryPicker, onComplete: PhotoRollAssetSource.refreshAssets)
  }
}
