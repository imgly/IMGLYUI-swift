import SwiftUI

/// A shape to put on top of a selected `ClipView` with leading and trailing trim handles.
struct ClipSelectionShape: Shape {
  let cornerRadius: CGFloat
  let trimHandleWidth: CGFloat

  private let markerSize = CGSize(width: 4, height: 1)

  func path(in rect: CGRect) -> Path {
    let outerPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius - 2).cgPath
    let insetRect = rect.insetBy(dx: trimHandleWidth, dy: 2)
    let maskPath = UIBezierPath(roundedRect: insetRect, cornerRadius: cornerRadius).reversing().cgPath

    var path = Path(outerPath)

    path.addPath(Path(maskPath))

    path.addPath(Path(trianglePath()),
                 transform: .init(translationX: trimHandleWidth - markerSize.width / 2, y: 0))

    path.addPath(Path(trianglePath(pointingUp: true)),
                 transform: .init(translationX: trimHandleWidth - markerSize.width / 2, y: rect.height))

    path.addPath(Path(trianglePath()),
                 transform: .init(translationX: rect.width - trimHandleWidth - markerSize.width / 2, y: 0))

    path.addPath(Path(trianglePath(pointingUp: true)),
                 transform: .init(translationX: rect.width - trimHandleWidth - markerSize.width / 2, y: rect.height))

    return path
  }

  private func trianglePath(pointingUp: Bool = false) -> CGPath {
    let triangle = UIBezierPath()

    triangle.move(to: .zero)

    // The order of the points matters: These are arranged counterclockwise
    // so they are already “reversed” and work as a mask.
    if pointingUp {
      triangle.addLine(to: CGPoint(x: markerSize.width, y: 0))
      triangle.addLine(to: CGPoint(x: markerSize.width / 2, y: -markerSize.height))
    } else {
      triangle.addLine(to: CGPoint(x: markerSize.width / 2, y: markerSize.height))
      triangle.addLine(to: CGPoint(x: markerSize.width, y: 0))
    }
    triangle.close()

    let path = triangle.cgPath
    return path
  }
}

struct ClipSelectionShape_Previews: PreviewProvider {
  static var previews: some View {
    ClipSelectionShape(cornerRadius: 8, trimHandleWidth: 12)
      .frame(height: 44)
      .padding()
  }
}
