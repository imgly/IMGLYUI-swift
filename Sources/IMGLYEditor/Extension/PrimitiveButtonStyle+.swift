import SwiftUI

extension PrimitiveButtonStyle where Self == BottomBarButtonStyle {
  static var bottomBar: Self { Self() }
}

extension PrimitiveButtonStyle where Self == OptionButtonStyle {
  static var option: Self { Self() }
}

public extension PrimitiveButtonStyle where Self == AssetLibraryButtonStyle {
  /// Creates a `PrimitiveButtonStyle` for the asset library.
  static var assetLibrary: Self { Self() }
}
