import SwiftUI
import UIKit

/// Window-aligned shimmer. Multiple instances could potentially be synced with `.matchedGeometryEffect`, a
/// `AnimatableModifier`, `TimelineView`, or by injecting the animation time somehow.
struct Shimmer: ViewModifier {
  @State private var windowSize: CGSize = .zero

  func body(content: Content) -> some View {
    content
      .background {
        GeometryReader { geo in
          // The global frame changes on rotation and window resizing, so the reader runs again even when the view
          // keeps its own size.
          WindowSizeReader(frameInWindow: geo.frame(in: .global)) { windowSize = $0 }
        }
      }
      .imgly.inverseMask {
        if windowSize != .zero {
          ShimmerGradient(windowSize: windowSize)
            // A new window size restarts the sweep, so the travel distance matches the window. `CGSize` is
            // `Hashable` only from iOS 18, so the identity is the pair of lengths.
            .id([windowSize.width, windowSize.height])
        }
      }
      .clipped()
  }
}

/// Sweeps a gradient across the whole window, so every instance moves in the same wave.
private struct ShimmerGradient: View {
  let windowSize: CGSize

  // Be careful with large angles and widths as it might increase the gradient view size significantly!
  private let gradientAngle = Angle(degrees: 15)
  private let gradientWidth: CGFloat = 400
  private let speedInPtPerSec: CGFloat = 200

  @State private var animation: Animation?
  @State private var target: CGFloat = 0

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

  private var getAnimation: Animation {
    let duration = windowSize.width / speedInPtPerSec
    return Animation.linear(duration: duration).repeatForever(autoreverses: false)
  }

  var body: some View {
    GeometryReader { geo in
      let rect = geo.frame(in: .global)
      let gradientSize = gradientSize(windowSize.height)
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
        .onChange(of: animation) { _ in
          // Restart animation
          animation = getAnimation
          target = windowSize.width + rotatedGradientSize.width
        }
        .animation(animation, value: target)
    }
  }
}

/// Reports the size of the window that hosts the view. `UIScreen.main` does not know which window a view is in, so
/// Split View and Stage Manager would get the size of the whole screen.
private struct WindowSizeReader: UIViewRepresentable {
  /// Read on every update, so SwiftUI runs the reader again whenever the view moves inside the window.
  let frameInWindow: CGRect
  let onChange: @MainActor (CGSize) -> Void

  func makeUIView(context _: Context) -> WindowSizeReaderView {
    let view = WindowSizeReaderView()
    view.onChange = onChange
    return view
  }

  func updateUIView(_ uiView: WindowSizeReaderView, context _: Context) {
    uiView.onChange = onChange
    uiView.reportWindowSize()
  }
}

private final class WindowSizeReaderView: UIView {
  var onChange: (@MainActor (CGSize) -> Void)?
  private var reportedSize: CGSize = .zero

  override func didMoveToWindow() {
    super.didMoveToWindow()
    reportWindowSize()
  }

  func reportWindowSize() {
    guard let size = window?.bounds.size, size != reportedSize else { return }
    reportedSize = size
    // `updateUIView` runs inside a SwiftUI update, so publish the size in the next main actor turn.
    Task { @MainActor [onChange] in
      onChange?(size)
    }
  }
}

struct Shimmer_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
