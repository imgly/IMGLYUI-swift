import Foundation
import Photos
import SwiftUI

@MainActor
@_spi(Internal) public final class PhotoLibraryAuthorizationManager: ObservableObject {
  @_spi(Internal) public static let shared = PhotoLibraryAuthorizationManager()

  @Published @_spi(Internal) public private(set) var authorizationStatus: PHAuthorizationStatus = .notDetermined

  @_spi(Internal) public var isAuthorized: Bool {
    authorizationStatus == .authorized || authorizationStatus == .limited
  }

  @_spi(Internal) public init() {
    authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
  }

  @_spi(Internal) public func requestPermission() async {
    switch authorizationStatus {
    case .notDetermined:
      authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    case .restricted, .denied:
      AppSettingsHelper.openAppSettings()
    case .authorized, .limited:
      break
    @unknown default:
      AppSettingsHelper.openAppSettings()
    }
  }
}
