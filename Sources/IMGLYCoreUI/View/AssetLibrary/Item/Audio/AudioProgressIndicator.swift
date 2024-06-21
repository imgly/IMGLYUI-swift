import SwiftUI

struct AudioProgressIndicator: View {
  let progress: Double

  var body: some View {
    Circle()
      .trim(from: 0, to: progress)
      .stroke(
        Color.white,
        style: SwiftUI.StrokeStyle(lineWidth: 3.2, lineCap: .round)
      )
      .rotationEffect(.degrees(-90))
      .animation(.easeOut, value: progress)
      .padding(1.6)
      .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 0)
  }
}
