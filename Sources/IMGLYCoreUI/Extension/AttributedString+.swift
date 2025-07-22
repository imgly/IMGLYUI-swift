import Foundation
@_spi(Internal) import IMGLYCore

extension AttributedString: IMGLYCompatible {}

public extension IMGLY where Wrapped == AttributedString {
  /// Removes the first occurrence of a string from the attributed string.
  /// - Parameter string: The string to remove.
  func remove(string: some StringProtocol) -> Wrapped {
    var result = wrapped
    if let range = result.range(of: string) {
      result.removeSubrange(range)
    }
    return result
  }
}
