import SwiftUI

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

@_spi(Internal) public extension LabelStyle where Self == AdaptiveIconOnlyLabelStyle {
  static var adaptiveIconOnly: Self { Self() }
}

extension LabelStyle where Self == AdaptiveTitleOnlyLabelStyle {
  static var adaptiveTitleOnly: Self { Self() }
}

extension LabelStyle where Self == BottomBarLabelStyle {
  static var bottomBar: Self { Self() }
  static func bottomBar(alignment: Alignment) -> Self { Self(alignment: alignment) }
}
