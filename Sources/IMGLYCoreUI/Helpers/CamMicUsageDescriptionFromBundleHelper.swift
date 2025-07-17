import Foundation

/// A helper to get the app name and usage descriptions from the main App’s bundle. These strings are used in custom
/// alerts that are shown after the user has initially denied access.
@_spi(Internal) public class CamMicUsageDescriptionFromBundleHelper {
  private let infoDictionary = Bundle.main.infoDictionary
  @_spi(Internal) public static let shared = CamMicUsageDescriptionFromBundleHelper()

  var appName: String? {
    infoDictionary?["CFBundleName"] as? String
  }

  @_spi(Internal) public var cameraAlertHeadline: String {
    if let appName {
      "“\(appName)” Would Like to Access Your Camera"
    } else {
      "This App Would Like to Access Your Camera"
    }
  }

  @_spi(Internal) public var microphoneAlertHeadline: String {
    if let appName {
      "“\(appName)” Would Like to Access Your Microphone"
    } else {
      "This App Would Like to Access Your Microphone"
    }
  }

  @_spi(Internal) public var cameraUsageDescription: String {
    infoDictionary?["NSCameraUsageDescription"] as? String ?? "We use the camera to record video."
  }

  @_spi(Internal) public var microphoneUsageDescription: String {
    infoDictionary?["NSMicrophoneUsageDescription"] as? String ?? "We use the microphone to record audio."
  }
}
