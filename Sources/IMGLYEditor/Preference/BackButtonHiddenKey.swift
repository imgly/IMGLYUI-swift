import SwiftUI

/// A `PreferenceKey` that indicates whether a `NavigationView` should hide its back button.
@available(
  *,
  unavailable,
  // swiftlint:disable:next line_length
  message: "Use `NavigationBar.Buttons.closeEditor` in combination with `.imgly.navigationBarItems` or `.imgly.modifyNavigationBarItems` view modifier to control the back button instead."
)
public struct BackButtonHiddenKey: PreferenceKey {
  public static let defaultValue: Bool = true
  public static func reduce(value: inout Bool, nextValue: () -> Bool) {
    value = value || nextValue()
  }
}
