import SwiftUI

/// Extends the landscape preview under the home indicator while keeping controls inside its inset.
struct CameraScreenLayout<Content: View>: View {
  let orientation: CameraOrientation
  @ViewBuilder var content: (EdgeInsets) -> Content

  var body: some View {
    GeometryReader { geometry in
      CameraRotationLayout(sideways: orientation.isLandscape) {
        content(controlInsets(homeIndicator: geometry.safeAreaInsets.bottom))
          .rotationEffect(.degrees(-Double(orientation.rawValue)))
      }
      .ignoresSafeArea(.container, edges: orientation.isLandscape ? .bottom : [])
    }
  }

  private func controlInsets(homeIndicator: CGFloat) -> EdgeInsets {
    guard orientation.isLandscape else { return EdgeInsets() }
    // Counter-rotation maps the screen's bottom inset onto a side of the portrait canvas.
    let isLeading = orientation == .landscapeLeft
    return EdgeInsets(top: 0, leading: isLeading ? homeIndicator : 0,
                      bottom: 0, trailing: isLeading ? 0 : homeIndicator)
  }
}
