import SwiftUI

/// A label style used for the ``CanvasMenu``.
public struct CanvasMenuLabelStyle: LabelStyle {
  public enum Style {
    /// A label style that only displays the title of the label.
    case titleAndIcon
    /// A label style that shows both the title and icon of the label.
    case titleOnly
    /// A label style that only displays the icon of the label.
    case iconOnly
  }

  var style: Style = .iconOnly
  var titleFont: Font? = .caption2.weight(.semibold)
  var iconFont: Font?
  @ScaledMetric var width = 48

  private func title(_ configuration: Configuration) -> some View {
    configuration.title
      .font(titleFont)
      .multilineTextAlignment(.leading)
      .lineLimit(2)
  }

  private func icon(_ configuration: Configuration) -> some View {
    configuration.icon
      .font(iconFont)
  }

  @_spi(Internal) public func makeBody(configuration: Configuration) -> some View {
    HStack {
      switch style {
      case .titleAndIcon:
        icon(configuration)
        title(configuration)
      case .titleOnly:
        title(configuration)
      case .iconOnly:
        icon(configuration)
      }
    }
    .padding([.leading, .trailing], 12)
    .frame(minWidth: width)
  }
}
