import SwiftUI
@_spi(Internal) import IMGLYCore

/// The custom animation curves.
@_spi(Internal) public extension IMGLY where Wrapped == Animation {
  static let timelineMinimizeMaximize =
    Wrapped.interpolatingSpring(mass: 0.16, stiffness: 11.7, damping: 5.37, initialVelocity: 9.9)
}
