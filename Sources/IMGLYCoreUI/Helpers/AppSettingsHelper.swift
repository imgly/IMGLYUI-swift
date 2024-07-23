import UIKit

@_spi(Internal) public enum AppSettingsHelper {
  @MainActor
  @_spi(Internal) public static func openAppSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}
