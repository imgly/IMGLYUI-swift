import SwiftUI

// MARK: - Public interface

public extension LabelStyle where Self == AdaptiveIconOnlyLabelStyle {
  /// Gets a namespace holder for `IMGLY` compatible types.
  static var imgly: IMGLY<Self>.Type { IMGLY<Self>.self }
}

public extension IMGLY where Wrapped == AdaptiveIconOnlyLabelStyle {
  /// An adaptive label style that displays the title and icon if the vertical size class is compact and only the icon
  /// otherwise.
  static var adaptiveIconOnly: Wrapped { Wrapped() }
}

public extension LabelStyle where Self == CanvasMenuLabelStyle {
  /// Gets a namespace holder for `IMGLY` compatible types.
  static var imgly: IMGLY<Self>.Type { IMGLY<Self>.self }
}

public extension IMGLY where Wrapped == CanvasMenuLabelStyle {
  /// A label style used for the ``CanvasMenu``.
  /// - Parameter style: The style of the label style.
  /// - Returns: The created label style.
  static func canvasMenu(_ style: Wrapped.Style) -> Wrapped { Wrapped(style: style) }
}

// MARK: - Internal interface

extension LabelStyle where Self == TileLabelStyle {
  static func tile(orientation: Self.Orientation) -> Self { Self(orientation: orientation) }
}

extension LabelStyle where Self == HiddenIconLabelStyle {
  static func icon(hidden: Bool, titleFont: SwiftUI.Font? = nil) -> Self {
    Self(hidden: hidden, titleFont: titleFont)
  }
}

extension LabelStyle where Self == AdaptiveTileLabelStyle {
  static var adaptiveTile: Self { Self() }
}

extension LabelStyle where Self == AdaptiveTitleOnlyLabelStyle {
  static var adaptiveTitleOnly: Self { Self() }
}

extension LabelStyle where Self == BottomBarLabelStyle {
  static var bottomBar: Self { Self() }
  static func bottomBar(alignment: Alignment) -> Self { Self(alignment: alignment) }
}
