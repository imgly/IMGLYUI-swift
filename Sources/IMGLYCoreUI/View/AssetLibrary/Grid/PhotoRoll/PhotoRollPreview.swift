@_spi(Internal) import IMGLYCore
import SwiftUI

/// A compact preview of photo roll assets that displays a limited number of items from the user's photo library,
/// or a permission request button if photo library access has not been granted.
public struct PhotoRollPreview: View {
  /// Creates a compact preview of photo roll assets with permission handling.
  public init() {}

  public var body: some View {
    AssetPreview.imageOrVideo {
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
    }
  }
}
