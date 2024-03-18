import SwiftUI

/// An animated dotted vertical line.
struct SnapIndicatorLineView: View {
  @State private var dashPhase: CGFloat = 0

  var body: some View {
    VerticalLine()
      .stroke(style: SwiftUI.StrokeStyle(lineWidth: 1, dash: [2], dashPhase: dashPhase))
      .frame(width: 1)
      .allowsHitTesting(false)
      .animation(Animation.linear.repeatForever(autoreverses: false).speed(0.3), value: dashPhase)
      .onAppear {
        dashPhase -= 4
      }
  }
}

struct SnapIndicatorLineView_Previews: PreviewProvider {
  static var previews: some View {
    SnapIndicatorLineView()
  }
}
