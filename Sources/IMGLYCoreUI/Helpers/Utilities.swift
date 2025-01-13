@_spi(Internal) import IMGLYCore

@_spi(Unstable) public func nonNil<T>(_ value: T?, file: StaticString = #file,
                                      function: String = #function,
                                      line: UInt = #line) throws -> T {
  guard let value else {
    throw Error(errorDescription: "Non nil unwrap failed in file `\(file)` and function `\(function)` on line \(line).")
  }
  return value
}
