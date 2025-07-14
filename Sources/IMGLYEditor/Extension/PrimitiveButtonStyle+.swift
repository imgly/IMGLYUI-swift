import SwiftUI

// MARK: - Public interface

public extension PrimitiveButtonStyle where Self == AssetLibraryButtonStyle {
  /// Gets a namespace holder for `IMGLY` compatible types.
  static var imgly: IMGLY<Self>.Type { IMGLY<Self>.self }
}

public extension IMGLY where Wrapped == AssetLibraryButtonStyle {
  /// A primitive button style for the asset library dock button.
  static var assetLibrary: Wrapped { Wrapped() }
}

// MARK: - Internal interface

extension PrimitiveButtonStyle where Self == BottomBarButtonStyle {
  static var bottomBar: Self { Self() }
}

extension PrimitiveButtonStyle where Self == OptionButtonStyle {
  static var option: Self { Self() }
}
