import SwiftUI

struct FeatureCloseLabelView: View {
  @ScaledMetric private var circleDiameter: Double = 48
  @ScaledMetric private var padding: Double = 4

  let isMinimized: Bool

  var body: some View {
    HStack {
      Image(systemName: "chevron.down")
        .rotationEffect(.degrees(isMinimized ? 0 : -180))
        .frame(width: circleDiameter, height: circleDiameter)
        .contentShape(Rectangle())
        .fontWeight(.semibold)
        .padding(padding)
        .animation(.easeInOut, value: isMinimized)

      Text("Close")
        .font(.caption)
        .fontWeight(.bold)
        .opacity(isMinimized ? 0 : 1)
    }
  }
}
