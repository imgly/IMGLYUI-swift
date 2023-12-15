@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct CanvasGeometryKey: PreferenceKey {
  static let defaultValue: Geometry? = nil
  static func reduce(value: inout Geometry?, nextValue: () -> Geometry?) {
    value = value ?? nextValue()
  }
}
