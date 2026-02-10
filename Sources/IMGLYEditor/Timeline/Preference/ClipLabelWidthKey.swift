import SwiftUI

/// PreferenceKey for communicating ClipLabelView's measured width to parent views.
struct ClipLabelWidthKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}
