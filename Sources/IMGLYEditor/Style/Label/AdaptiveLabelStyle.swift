import SwiftUI

private struct AdaptiveLabelStyle<Compact: LabelStyle, Normal: LabelStyle>: LabelStyle {
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  let compactStyle: Compact
  let normalStyle: Normal

  init(compactStyle: Compact, normalStyle: Normal) {
    self.compactStyle = compactStyle
    self.normalStyle = normalStyle
  }

  func makeBody(configuration: Configuration) -> some View {
    if verticalSizeClass == .compact {
      Label(configuration)
        .labelStyle(compactStyle)
    } else {
      Label(configuration)
        .labelStyle(normalStyle)
    }
  }
}

struct AdaptiveTileLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    Label(configuration)
      .labelStyle(AdaptiveLabelStyle(
        compactStyle: .tile(orientation: .horizontal),
        normalStyle: .tile(orientation: .vertical)
      ))
  }
}

/// An adaptive label style that displays the title and icon if the vertical size class is compact and only the icon
/// otherwise.
public struct AdaptiveIconOnlyLabelStyle: LabelStyle {
  @_spi(Internal) public func makeBody(configuration: Configuration) -> some View {
    Label(configuration)
      .labelStyle(AdaptiveLabelStyle(compactStyle: .titleAndIcon, normalStyle: .iconOnly))
  }
}

struct AdaptiveTitleOnlyLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    Label(configuration)
      .labelStyle(AdaptiveLabelStyle(compactStyle: .titleAndIcon, normalStyle: .titleOnly))
  }
}

struct BottomBarLabelStyle: LabelStyle {
  static let titleFont = SwiftUI.Font.caption2.weight(.semibold)
  static let size = CGSize(width: 64, height: 56)

  var alignment: Alignment = .center

  func makeBody(configuration: Configuration) -> some View {
    Label(configuration)
      .labelStyle(AdaptiveLabelStyle(
        compactStyle: TileLabelStyle(
          orientation: .horizontal,
          titleFont: Self.titleFont,
          size: Self.size,
          alignment: alignment
        ),
        normalStyle: TileLabelStyle(
          orientation: .vertical,
          titleFont: Self.titleFont,
          size: Self.size,
          alignment: alignment
        )
      ))
      .padding(.horizontal, 4)
  }
}
