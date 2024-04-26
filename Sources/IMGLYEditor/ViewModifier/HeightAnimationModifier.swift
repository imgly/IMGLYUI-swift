import SwiftUI

/// A modifier to animate height changes.
struct HeightAnimationModifier: ViewModifier, Animatable {
  var targetHeight: CGFloat

  var animatableData: CGFloat {
    get { targetHeight }
    set { targetHeight = newValue }
  }

  func body(content: Content) -> some View {
    content.frame(height: targetHeight)
  }
}
