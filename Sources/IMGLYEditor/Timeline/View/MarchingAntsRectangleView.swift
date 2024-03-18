import SwiftUI

/// An animated dotted rounded rectangle.
struct MarchingAntsRectangleView: View {
  let cornerRadius: CGFloat
  @State private var dashPhase: CGFloat = 0

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .inset(by: -1)
      .strokeBorder(style: SwiftUI.StrokeStyle(lineWidth: 1, dash: [2], dashPhase: dashPhase))
      .animation(Animation.linear.repeatForever(autoreverses: false).speed(0.3), value: dashPhase)
      .opacity(1)
      .onAppear {
        dashPhase -= 4
      }
  }
}

struct MarchingAntsRectangleView_Previews: PreviewProvider {
  static var previews: some View {
    MarchingAntsRectangleView(cornerRadius: 8)
      .frame(width: 100, height: 100)
  }
}
