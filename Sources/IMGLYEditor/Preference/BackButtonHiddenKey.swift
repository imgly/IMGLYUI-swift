import SwiftUI

/// A `PreferenceKey` that indicates whether a `NavigationView` should hide its back button.
public struct BackButtonHiddenKey: PreferenceKey {
  public static let defaultValue: Bool = false
  public static func reduce(value: inout Bool, nextValue: () -> Bool) {
    value = value || nextValue()
  }
}
