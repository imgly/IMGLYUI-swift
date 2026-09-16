import SwiftUI

/// Simple helper struct for wrapping options in a picker.
struct PickerOption<T: Hashable>: Identifiable, Equatable {
  var label: LocalizedStringResource
  var icon: Image
  var tag: T
  var id: T {
    tag
  }
}
