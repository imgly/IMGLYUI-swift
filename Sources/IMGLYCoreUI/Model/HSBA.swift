import SwiftUI
import UIKit

protocol HSBAConvertible {
  var hsba: HSBA? { get }
}

struct HSBA: Equatable {
  let hue: CGFloat
  let saturation: CGFloat
  let brightness: CGFloat
  let alpha: CGFloat

  var isTransparent: Bool {
    let threshold = 0.2
    return alpha < threshold
  }

  var isGray: Bool {
    let threshold = 0.1
    return saturation < threshold || brightness < threshold
  }

  typealias Predicate<T: HSBAConvertible> = (_ color: T) -> Bool
  typealias Comparator<T: HSBAConvertible> = (_ lhs: T, _ rhs: T) -> Bool

  static func predicate<T>(_ keyPath: KeyPath<HSBA, Bool>) -> Predicate<T> {
    { color in
      let color = color.hsba
      guard let color else {
        return false
      }
      return color[keyPath: keyPath]
    }
  }

  static func comparator<T>(_ keyPath: KeyPath<HSBA, some Comparable>, order: SortOrder = .forward) -> Comparator<T> {
    { lhs, rhs in
      let lhs = lhs.hsba
      let rhs = rhs.hsba
      guard let lhs, let rhs else {
        assert(lhs == rhs, "Revise sorting for colors that cannot be converted to HSBA.")
        return lhs != nil
      }
      switch order {
      case .forward:
        return lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
      case .reverse:
        return lhs[keyPath: keyPath] > rhs[keyPath: keyPath]
      }
    }
  }
}

extension HSBA {
  init?(_ color: UIColor) {
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    if color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
      self.init(hue: h, saturation: s, brightness: b, alpha: a)
    } else {
      return nil
    }
  }

  init?(_ color: CGColor) {
    self.init(UIColor(cgColor: color))
  }

  init?(_ color: Color) {
    self.init(color.asCGColor)
  }
}

extension HSBA: CustomStringConvertible {
  var description: String {
    String(format: "h: %.2f s: %.2f b: %.2f a: %.2f", hue, saturation, brightness, alpha)
  }
}
