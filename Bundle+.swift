import Foundation

extension Bundle {
  private final class CurrentBundleFinder {}

  static var module = Bundle(for: CurrentBundleFinder.self)
}
