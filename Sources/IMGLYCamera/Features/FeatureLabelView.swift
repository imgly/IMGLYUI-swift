import SwiftUI

struct FeatureLabelView: View {
  @ScaledMetric var circleDiameter: Double = 48
  @ScaledMetric var padding: Double = 4

  let text: LocalizedStringResource
  let image: Image

  let isSelected: Bool
  let hasLabel: Bool

  var body: some View {
    HStack {
      Rectangle()
        .fill(.clear)
        .frame(width: circleDiameter, height: circleDiameter)
        .background {
          if isSelected {
            Circle()
              .mask {
                Rectangle()
                image
                  .blendMode(.destinationOut)
              }
          } else {
            image
          }
        }
        .font(.title2)
        .padding(padding)

      Text(text)
        .font(.callout)
        .opacity(hasLabel ? 1 : 0)
        .animation(.linear, value: hasLabel)
    }
    .foregroundColor(.white)
    .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 4)
    .fontWeight(.medium)
    .fixedSize()
    .animation(nil, value: isSelected)
  }
}
