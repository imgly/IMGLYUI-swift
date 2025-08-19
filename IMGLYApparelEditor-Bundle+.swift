import Foundation

extension Bundle {
  private final class CurrentBundleFinder {}
  static let module: Bundle = {
    // If the app is built using static CocoaPods the resource bundle will be in the app's main bundle.
    if
      let assetBundleURL = Bundle.main.url(forResource: "IMGLYApparelEditorAssets", withExtension: "bundle"),
      let resourceBundle = Bundle(url: assetBundleURL) {
      return resourceBundle
    }

    // If the app is built using dynamic CocoaPods the resource bundle will be embedded in the framework's bundle.
    let frameworkBundle = Bundle(for: CurrentBundleFinder.self)

    // Derive the bundle name for CocoaPods.
    let bundleName = frameworkBundle.bundleURL.deletingPathExtension().lastPathComponent + "Assets"

    // If specific asset bundle exists use this otherwise fall back to framework bundle.
    if
      let resourceBundleURL = frameworkBundle.url(forResource: bundleName, withExtension: "bundle"),
      let resourceBundle = Bundle(url: resourceBundleURL) {
      return resourceBundle
    } else {
      return frameworkBundle
    }
  }()
}
