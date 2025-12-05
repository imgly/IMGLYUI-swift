@_spi(Internal) import IMGLYCore
import SwiftUI

/// An accessory view for photo roll assets that displays either an add menu button when photo library access is
/// authorized, or a permissions request button when access is not yet granted.
public struct PhotoRollAccessory: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
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
      if interactor.isPhotoRollFullLibraryAccessEnabled {
        if photoLibraryManager.isAuthorized {
          PhotoRollAddMenu(media: media) {
            AddLabel()
          }
        } else {
          PhotoRollPermissionsButton()
        }
      } else {
        UploadMenu(media: media.map(\.mediaType)) {
          AddLabel()
        }
      }
    }
    .onAppear(perform: updateConfiguration)
    .onChange(of: photoLibraryManager.isAuthorized) { _ in
      updateConfiguration()
    }
  }

  func updateConfiguration() {
    configuration.isNavigationAllowed = interactor.isPhotoRollFullLibraryAccessEnabled ? photoLibraryManager
      .isAuthorized : true
  }
}
