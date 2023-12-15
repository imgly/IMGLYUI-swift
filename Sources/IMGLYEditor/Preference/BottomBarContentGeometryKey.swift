@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct BottomBarContentGeometryKey: PreferenceKey {
  static let defaultValue: Geometry? = nil
  static func reduce(value: inout Geometry?, nextValue: () -> Geometry?) {
    value = value ?? nextValue()
  }
}
