import Foundation

/// A helper to get the app name and usage descriptions from the main App’s bundle. These strings are used in custom
/// alerts that are shown after the user has initially denied access.
class CamMicUsageDescriptionFromBundleHelper {
  let infoDictionary = Bundle.main.infoDictionary
  static let shared = CamMicUsageDescriptionFromBundleHelper()

  lazy var appName: String? = {
    infoDictionary?["CFBundleName"] as? String
  }()

  lazy var cameraAlertHeadline: String = {
    if let appName {
      return "“\(appName)” Would Like to Access Your Camera"
    } else {
      return "This App Would Like to Access Your Camera"
    }
  }()

  lazy var microphoneAlertHeadline: String = {
    if let appName {
      return "“\(appName)” Would Like to Access Your Microphone"
    } else {
      return "This App Would Like to Access Your Microphone"
    }
  }()

  lazy var cameraUsageDescription: String = {
    infoDictionary?["NSCameraUsageDescription"] as? String ?? "We use the camera to record video."
  }()

  lazy var microphoneUsageDescription: String = {
    infoDictionary?["NSMicrophoneUsageDescription"] as? String ?? "We use the microphone to record audio."
  }()
}
