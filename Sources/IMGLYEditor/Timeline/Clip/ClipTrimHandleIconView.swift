import SwiftUI

/// An icon that changes its shape from a vertical line to a left- or right-pointing chevron.
struct ClipTrimHandleIconView: View {
  enum Style {
    case neutral
    case left
    case right

    var iconPath: Path {
      let path = switch self {
      case .neutral:
        Path { path in
          path.move(to: CGPoint(x: 2, y: 0))
          path.addLine(to: CGPoint(x: 2, y: 12))
        }
      case .left:
        Path { path in
          path.move(to: CGPoint(x: 3, y: 0))
          path.addLine(to: CGPoint(x: 0, y: 6))
          path.addLine(to: CGPoint(x: 3, y: 12))
        }
      case .right:
        Path { path in
          path.move(to: CGPoint(x: 1, y: 0))
          path.addLine(to: CGPoint(x: 4, y: 6))
          path.addLine(to: CGPoint(x: 1, y: 12))
        }
      }
      return path
    }
  }

  let style: Style
  let color: Color

  var body: some View {
    let lineStyle = SwiftUI.StrokeStyle(lineWidth: style == .neutral ? 4 : 3.5, lineCap: .round, lineJoin: .miter)

    style.iconPath
      .stroke(color, style: lineStyle)
      .frame(width: 4, height: 12)
  }
}

struct ClipTrimHandleIconView_Previews: PreviewProvider {
  static var previews: some View {
    HStack {
      ClipTrimHandleIconView(style: .neutral, color: .primary)
      ClipTrimHandleIconView(style: .left, color: .primary)
      ClipTrimHandleIconView(style: .right, color: .primary)
    }
  }
}
