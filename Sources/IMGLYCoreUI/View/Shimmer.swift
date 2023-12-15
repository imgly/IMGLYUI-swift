import SwiftUI

/// Screen-aligned shimmer. Multiple instances could potentially be synced with `.matchedGeometryEffect`, a
/// `AnimatableModifier` or by injecting the animation time somehow.
struct Shimmer: ViewModifier {
  // Be careful with large angles and widths as it might increase the gradient view size significantly!
  private let gradientAngle = Angle(degrees: 15)
  private let gradientWidth: CGFloat = 400

  private func gradientHeight(_ coveredHeight: CGFloat) -> CGFloat {
    let heightForZeroWidth = coveredHeight / cos(gradientAngle.radians)
    let heightForWidth = gradientWidth * tan(gradientAngle.radians)
    return heightForZeroWidth + heightForWidth
  }

  private func gradientSize(_ coveredHeight: CGFloat) -> CGSize {
    .init(width: gradientWidth, height: gradientHeight(coveredHeight))
  }

  private func rotatedGradientSize(_ size: CGSize) -> CGSize {
    var rect = CGRect(origin: .zero, size: size)
    rect = rect.offsetBy(dx: rect.midX, dy: rect.midY)
    rect = rect.applying(.init(rotationAngle: gradientAngle.radians))
    return rect.size
  }

  private var rotatedGradientOffset: CGFloat {
    sin(gradientAngle.radians) * gradientWidth
  }

  private let speedInPtPerSec: CGFloat = 200

  @MainActor
  private var getAnimation: Animation {
    let duration = UIScreen.main.bounds.width / speedInPtPerSec
    return Animation.linear(duration: duration).repeatForever(autoreverses: false)
  }

  @State private var animation: Animation?
  @State private var target: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .imgly.inverseMask {
        GeometryReader { geo in
          let rect = geo.frame(in: .global)
          let gradientSize = gradientSize(UIScreen.main.bounds.height)
          let rotatedGradientSize = rotatedGradientSize(gradientSize)

          LinearGradient(colors: [.clear, .black, .clear],
                         startPoint: .leading,
                         endPoint: .trailing)
            .frame(width: gradientSize.width, height: gradientSize.height)
            .rotationEffect(gradientAngle)
            .position(x: -rect.origin.x - (rotatedGradientSize.width / 2) + target,
                      y: -rect.origin.y + (rotatedGradientSize.height / 2) - rotatedGradientOffset)
            .onAppear {
              animation = getAnimation
            }
            .onChange(of: UIScreen.main.bounds.size) { _ in
              // Handle screen orientation changes
              target = 0
              animation = nil
            }
            .onChange(of: animation) { _ in
              // Restart animation
              animation = getAnimation
              target = UIScreen.main.bounds.width + rotatedGradientSize.width
            }
            .animation(animation, value: target)
        }
      }
      .clipped()
  }
}

struct Shimmer_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
