@_spi(Internal) import IMGLYCore

/// Unwraps an optional and throws if it was `nil`.
/// - Parameters:
///   - value: Some optional value that should be unwrapped.
///   - file: The file in which the unwrap occurred.
///   - function: The function in which the unwrap occurred.
///   - line: The line at which the unwrap occurred.
/// - Throws: If the provided `value` was `nil`.
/// - Returns: The unwrapped `value`.
public func nonNil<T>(_ value: T?,
                      file: StaticString = #file,
                      function: String = #function,
                      line: UInt = #line) throws -> T {
  guard let value else {
    throw Error(errorDescription: "Non nil unwrap failed in file `\(file)` and function `\(function)` on line \(line).")
  }
  return value
}
