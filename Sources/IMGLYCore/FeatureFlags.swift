import Foundation
import SwiftUI

@_spi(Internal) public enum FeatureFlag: String, CaseIterable {
  case designEditor
  case sceneUpload
  case photosPicker
  case photosPickerEncodingOptions
  case transcodePickerImports
  /// By default, the `DesignEditor` will export PDFs.
  /// If this flag is set, it will export PNGs instead.
  case exportPNGInDesignEditor
  /// By default, the engine works in an 8-bit sRGB color space and exports 8bit images which lose P3 color information.
  /// If this flag is enabled, the engine works in 16-bit extended sRGB and exports 16bit images in the P3 color space.
  case exportP3Images

  fileprivate var isInitiallyEnabled: Bool {
    switch self {
    case .designEditor, .transcodePickerImports: true
    default:
      ProcessInfo.processInfo.arguments.contains(launchArgument)
    }
  }

  @_spi(Internal) public var launchArgument: String {
    "IMGLYUI_FEATURE_FLAG_\(rawValue)"
  }
}

/// Access all `FeatureFlag`s.
@propertyWrapper
@_spi(Internal) public struct Features: DynamicProperty {
  @ObservedObject private var featureFlags = FeatureFlags.shared

  @_spi(Internal) public init() {}

  @_spi(Internal) public var wrappedValue: FeatureFlags {
    featureFlags
  }
}

/// Access a specific `FeatureFlag`.
@propertyWrapper
@_spi(Internal) public struct Feature: DynamicProperty {
  @Features private var features
  private let flag: FeatureFlag

  @_spi(Internal) public init(_ flag: FeatureFlag) {
    self.flag = flag
  }

  @_spi(Internal) public var wrappedValue: Bool {
    features.isEnabled(flag)
  }
}

/// State storage for `FeatureFlag`s.
@_spi(Internal) public class FeatureFlags: ObservableObject {
  @Published private var enabled: Set<FeatureFlag>

  /// Check if a feature flag is enabled.
  @_spi(Internal) public func isEnabled(_ flag: FeatureFlag) -> Bool {
    enabled.contains(flag)
  }

  /// Set a feature flag.
  @_spi(Internal) public func setEnabled(_ flag: FeatureFlag, value: Bool) {
    if value {
      enabled.insert(flag)
    } else {
      enabled.remove(flag)
    }
  }

  private init() {
    enabled = .init(FeatureFlag.allCases.filter(\.isInitiallyEnabled))
  }

  @MainActor fileprivate static let shared = FeatureFlags()

  /// Check if a feature flag is enabled. **Don't use this in SwiftUI `View`s!**
  /// - Attention: For SwiftUI `View`s use `@Features` or `@Feature(_:)` to access `FeatureFlag`s instead which will
  /// update the view if they change.
  @MainActor @_spi(Internal) public static func isEnabled(_ flag: FeatureFlag) -> Bool {
    shared.isEnabled(flag)
  }

  /// Set a feature flag.
  @MainActor @_spi(Internal) public static func setEnabled(_ flag: FeatureFlag, value: Bool) {
    shared.setEnabled(flag, value: value)
  }
}
