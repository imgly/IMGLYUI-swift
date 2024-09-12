import Foundation

extension Bundle {
  private final class CurrentBundleFinder {}

  static let module = Bundle(for: CurrentBundleFinder.self)
}
