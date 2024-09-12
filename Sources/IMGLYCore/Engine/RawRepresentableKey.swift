import Foundation

@_spi(Internal) public enum RawRepresentableKey<T>: Hashable, RawRepresentable where T: RawRepresentable,
  T.RawValue == String {
  case key(T)
  case raw(String)

  @_spi(Internal) public init(_ key: T) {
    self = .key(key)
  }

  @_spi(Internal) public init(rawValue: String) {
    if let key = T(rawValue: rawValue) {
      self = .key(key)
    } else {
      self = .raw(rawValue)
    }
  }

  @_spi(Internal) public var rawValue: String {
    switch self {
    case let .key(key): key.rawValue
    case let .raw(raw): raw
    }
  }
}
