import SwiftUI

struct TileLabelStyle: LabelStyle {
  enum Orientation {
    case vertical, horizontal
  }

  typealias Font = SwiftUI.Font

  var orientation = Orientation.vertical
  var titleFont = Font.footnote
  var iconFont = Font.title2
  var size = CGSize(width: 83, height: 60)
  var alignment: Alignment = .center

  private func title(_ configuration: Configuration) -> some View {
    configuration.title
      .font(titleFont)
  }

  private func icon(_ configuration: Configuration) -> some View {
    configuration.icon
      .font(iconFont)
      .frame(height: 26)
  }

  func makeBody(configuration: Configuration) -> some View {
    if orientation == .horizontal {
      HStack {
        icon(configuration)
        title(configuration)
      }
      .frame(idealWidth: size.width + 33, maxWidth: .infinity, alignment: alignment)
      .frame(height: 33)
    } else {
      VStack(spacing: 4) {
        icon(configuration)
        title(configuration)
      }
      .frame(idealWidth: size.width, maxWidth: .infinity, alignment: alignment)
      .frame(height: size.height)
    }
  }
}
