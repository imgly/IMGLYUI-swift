import Foundation

@_spi(Internal) public extension ProcessInfo {
  static var isUITesting: Bool { ProcessInfo.processInfo.arguments.contains("UI-Testing") }

  static var isSwiftUIPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }
}
