import SwiftUI

/// A generic vertical line shape constructed from a single path.
struct VerticalLine: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: 0, y: 0))
    path.addLine(to: CGPoint(x: 0, y: rect.height))
    return path
  }
}

struct VerticalLine_Previews: PreviewProvider {
  static var previews: some View {
    VerticalLine()
      .stroke(Color.pink, lineWidth: 1)
      .frame(width: 1, height: 100)
  }
}
