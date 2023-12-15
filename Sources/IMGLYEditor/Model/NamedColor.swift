import SwiftUI

public struct NamedColor: Identifiable, Hashable {
  public var id: CGColor { color }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(color)
  }

  public let name: LocalizedStringKey
  public let color: CGColor

  public init(_ name: LocalizedStringKey, _ color: CGColor) {
    self.name = name
    self.color = color
  }
}
