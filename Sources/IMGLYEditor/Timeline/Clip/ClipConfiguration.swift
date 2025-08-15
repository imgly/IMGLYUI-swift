import SwiftUI

/// Configure `ClipView` appearance properties.
struct ClipConfiguration {
  let color: Color
  let backgroundColor: Color
  let icon: Image

  static let `default`: ClipConfiguration = .init(
    color: .primary,
    backgroundColor: .accentColor,
    icon: Image(systemName: "square.slash")
  )
}
