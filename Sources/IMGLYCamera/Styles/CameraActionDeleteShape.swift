import SwiftUI

struct CameraActionDeleteShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let width = rect.size.width
    let height = rect.size.height
    path.move(
      to: CGPoint(x: 0.18533 * width, y: 0.174 * height),
    )
    path.addLine(
      to: CGPoint(x: 0.124 * width, y: 0.25 * height),
    )
    path.addCurve(
      to: CGPoint(x: 0, y: 0.5 * height),
      control1: CGPoint(x: 0.044 * width, y: 0.348 * height),
      control2: CGPoint(x: 0, y: 0.418 * height),
    )
    path.addCurve(
      to: CGPoint(x: 0.12267 * width, y: 0.748 * height),
      control1: CGPoint(x: 0, y: 0.582 * height),
      control2: CGPoint(x: 0.044 * width, y: 0.65 * height),
    )
    path.addLine(
      to: CGPoint(x: 0.184 * width, y: 0.824 * height),
    )
    path.addCurve(
      to: CGPoint(x: 0.54 * width, y: height),
      control1: CGPoint(x: 0.30133 * width, y: 0.97 * height),
      control2: CGPoint(x: 0.37067 * width, y: height),
    )
    path.addLine(
      to: CGPoint(x: 0.824 * width, y: height),
    )
    path.addCurve(
      to: CGPoint(x: width, y: 0.736 * height),
      control1: CGPoint(x: 0.93867 * width, y: height),
      control2: CGPoint(x: width, y: 0.908 * height),
    )
    path.addLine(
      to: CGPoint(x: width, y: 0.264 * height),
    )
    path.addCurve(
      to: CGPoint(x: 0.824 * width, y: 0),
      control1: CGPoint(x: width, y: 0.092 * height),
      control2: CGPoint(x: 0.93867 * width, y: 0),
    )
    path.addLine(
      to: CGPoint(x: 0.54 * width, y: 0),
    )
    path.addCurve(
      to: CGPoint(x: 0.18533 * width, y: 0.174 * height),
      control1: CGPoint(x: 0.36933 * width, y: 0),
      control2: CGPoint(x: 0.30133 * width, y: 0.03 * height),
    )
    path.closeSubpath()
    return path
  }
}
