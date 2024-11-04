import Foundation

extension Bundle {
  private final class CurrentBundleFinder {}

  static var module: Bundle = {
    let frameworkBundle = Bundle(for: CurrentBundleFinder.self)

    // Derive the bundle name for CocoaPods.
    let bundleName = frameworkBundle.bundleURL.deletingPathExtension().lastPathComponent + "Assets"

    // If specific asset bundle exists use this otherwise fall back to
    // framework bundle.
    if let resourceBundleURL = frameworkBundle.url(forResource: bundleName, withExtension: "bundle"),
       let resourceBundle = Bundle(url: resourceBundleURL) {
      return resourceBundle
    } else {
      return frameworkBundle
    }
  }()
}
