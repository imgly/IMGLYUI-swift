@_spi(Internal) import IMGLYCore
import SwiftUI

/// An accessory view for photo roll assets that displays either an add menu button when photo library access is
/// authorized, or a permissions request button when access is not yet granted.
public struct PhotoRollAccessory: View {
  @StateObject private var photoLibraryManager = PhotoLibraryAuthorizationManager.shared
  @EnvironmentObject private var configuration: AssetLibrarySectionConfiguration
  private let media: [PhotoRollMediaType]

  /// Creates an accessory view for photo roll assets that adapts based on photo library permissions.
  /// - Parameter media: The allowed media type(s).
  public init(media: [PhotoRollMediaType]) {
    self.media = media
  }

  public var body: some View {
    HStack {
      if photoLibraryManager.isAuthorized {
        PhotoRollAddMenu(media: media) {
          AddLabel()
        }
      } else {
        PhotoRollPermissionsButton()
      }
    }
    .onAppear(perform: updateConfiguration)
    .onChange(of: photoLibraryManager.isAuthorized) { _ in
      updateConfiguration()
    }
  }

  func updateConfiguration() {
    configuration.isNavigationAllowed = photoLibraryManager.isAuthorized
  }
}
