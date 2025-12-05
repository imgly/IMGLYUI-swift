@_spi(Internal) import IMGLYCore
import SwiftUI

/// A compact preview of photo roll assets.
public struct PhotoRollPreview: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor

  /// Creates a compact preview of photo roll assets.
  public init() {}

  public var body: some View {
    AssetPreview.imageOrVideo {
      if interactor.isPhotoRollFullLibraryAccessEnabled {
        if PhotoLibraryAuthorizationManager.shared.isAuthorized {
          Message.noElements
        } else {
          Button {
            Task {
              await PhotoLibraryAuthorizationManager.shared.requestPermission()
              if PhotoLibraryAuthorizationManager.shared.isAuthorized {
                PhotoRollAssetSource.refreshAssets()
              }
            }
          } label: {
            Message(.imgly.localized("ly_img_editor_asset_library_label_grant_permissions"))
          }
        }
      } else {
        Message.noElements
      }
    }
  }
}
