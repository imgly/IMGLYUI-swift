import SwiftUI

struct KeyboardToolbarSafeAreaInsetsKey: PreferenceKey {
  static let defaultValue: EdgeInsets? = nil
  static func reduce(value: inout EdgeInsets?, nextValue: () -> EdgeInsets?) {
    value = value ?? nextValue()
  }
}
