import SwiftUI

/// A custom shape with a line flanked by circles at both ends.
struct LineWithCirclesShape: Shape {
  // MARK: - Constants

  private enum Constants {
    static let widthLine: CGFloat = 1.0
    static let circleToLineRatio: CGFloat = 3.0
  }

  // MARK: - Properties

  var lineWidth: CGFloat

  // MARK: - Initializers

  /// Initializes the shape with a specified line width.
  /// - Parameter lineWidth: The width of the line, defaulting to 1.0.
  init(lineWidth: CGFloat = Constants.widthLine) {
    self.lineWidth = lineWidth
  }

  // MARK: - Path Definition

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let circleDiameter = lineWidth * Constants.circleToLineRatio
    let circleRadius = circleDiameter / 2
    let lineOffset = (rect.width - lineWidth) / 2
    let topCircleCenter = CGPoint(x: rect.midX, y: rect.minY + circleRadius)
    let bottomCircleCenter = CGPoint(x: rect.midX, y: rect.maxY - circleRadius)

    // Top circle
    path.addEllipse(in: CGRect(x: topCircleCenter.x - circleRadius, y: topCircleCenter.y - circleRadius,
                               width: circleDiameter, height: circleDiameter))

    // Line
    path.addRect(CGRect(x: lineOffset, y: topCircleCenter.y,
                        width: lineWidth, height: rect.height - circleDiameter))

    // Bottom circle
    path.addEllipse(in: CGRect(x: bottomCircleCenter.x - circleRadius, y: bottomCircleCenter.y - circleRadius,
                               width: circleDiameter, height: circleDiameter))

    return path
  }
}

// MARK: - Previews

#Preview {
  LineWithCirclesShape()
}
