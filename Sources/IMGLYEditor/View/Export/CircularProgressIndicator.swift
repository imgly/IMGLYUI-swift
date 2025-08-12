import SwiftUI

struct CircularProgressIndicator: View {
  let current: Double
  let total: Double

  @ScaledMetric private var strokeWidth: CGFloat = 8

  @State private var rotation: Angle = .degrees(0)

  private let indeterminateRotationSpeed: TimeInterval = 1.5

  var body: some View {
    let value = min(1, max(0, current / total))
    ZStack {
      Circle()
        .inset(by: strokeWidth / 2)
        .stroke(.primary.opacity(0.05), lineWidth: strokeWidth)
      Circle()
        .inset(by: strokeWidth / 2)
        .rotation(.degrees(-90))
        .trim(
          from: 0,
          to: value,
        )
        .stroke(
          Color.accentColor,
          style: StrokeStyle(
            lineWidth: strokeWidth,
            lineCap: .round,
          ),
        )
      if value < 1 {
        Circle()
          .inset(by: strokeWidth / 2)
          .stroke(
            AngularGradient(
              gradient: Gradient(colors: [.clear, .primary.opacity(0.1)]),
              center: .center,
              startAngle: .zero + rotation,
              endAngle: .degrees(180) + rotation,
            ),
            style: StrokeStyle(
              lineWidth: strokeWidth,
              lineCap: .round,
            ),
          )
          .animation(
            .linear(duration: indeterminateRotationSpeed).repeatForever(autoreverses: false),
            value: rotation,
          )

        Text(value, format: .percent.precision(.fractionLength(0)))
          .font(.footnote)
          .fontWeight(.bold)
          .monospacedDigit()
      }
    }
    .task {
      // Fix visual glitch where the animation would start at the wrong origin.
      try? await Task.sleep(for: .milliseconds(100))
      rotation = .degrees(360)
    }
  }
}

struct CircularProgressIndicator_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      CircularProgressIndicator(current: 0, total: 100)
      CircularProgressIndicator(current: 33.333333, total: 100)
      CircularProgressIndicator(current: 50, total: 100)
      CircularProgressIndicator(current: 100, total: 100)
    }
    .padding()
    .frame(height: 400)
  }
}
