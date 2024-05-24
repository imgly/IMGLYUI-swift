import SwiftUI

/// A named color that is composed of a name, required for accessibility, and the actual `CGColor` to use.
public struct NamedColor: Identifiable, Hashable {
  public var id: CGColor { color }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(color)
  }

  /// The color name.
  public let name: LocalizedStringKey
  /// The color value.
  public let color: CGColor

  /// Creates a named color.
  /// - Parameters:
  ///   - name: The color name.
  ///   - color: The color value.
  public init(_ name: LocalizedStringKey, _ color: CGColor) {
    self.name = name
    self.color = color
  }
}
