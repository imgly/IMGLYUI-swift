@_spi(Internal) import IMGLYCore
import SwiftUI

struct PhotoRollPermissionsButton: View {
  var body: some View {
    Button {
      Task {
        await PhotoLibraryAuthorizationManager.shared.requestPermission()
        if PhotoLibraryAuthorizationManager.shared.isAuthorized {
          PhotoRollAssetSource.refreshAssets()
        }
      }
    } label: {
      Text(.imgly.localized("ly_img_editor_asset_library_button_permissions"))
      Image(systemName: "chevron.forward")
    }
    .font(.subheadline.weight(.semibold).monospacedDigit())
  }
}
