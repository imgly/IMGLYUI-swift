import SwiftUI
@_spi(Internal) import IMGLYCore

/// The custom animation curves.
extension IMGLY where Wrapped == Animation {
  static let flip =
    Wrapped.interpolatingSpring(mass: 0.2, stiffness: 13.95, damping: 2.23, initialVelocity: 4.95)
  static let growShrinkSlow =
    Wrapped.interpolatingSpring(mass: 0.22, stiffness: 11.7, damping: 2.9, initialVelocity: 0.0)
  static let growShrinkQuick =
    Wrapped.interpolatingSpring(mass: 0.16, stiffness: 11.7, damping: 3.5, initialVelocity: 10)
  static let slide =
    Wrapped.interpolatingSpring(mass: 0.04, stiffness: 4.1, damping: 0.94, initialVelocity: 10)
}
