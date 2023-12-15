import Foundation

extension Dictionary {
  /// Transforms dictionary keys without modifying values.
  /// Deduplicates transformed keys.
  ///
  /// Example:
  /// ```
  /// ["one": 1, "two": 2, "three": 3, "": 4].mapKeys({ $0.first }, uniquingKeysWith: { max($0, $1) })
  /// // [Optional("o"): 1, Optional("t"): 3, nil: 4]
  /// ```
  ///
  /// - Parameters:
  ///   - transform: A closure that accepts each key of the dictionary as
  ///   its parameter and returns a transformed key of the same or of a different type.
  ///   - combine:A closure that is called with the values for any duplicate
  ///   keys that are encountered. The closure returns the desired value for
  ///   the final dictionary.
  /// - Returns: A dictionary containing the transformed keys and values of this dictionary.
  func mapKeys<T>(_ transform: (Key) throws -> T,
                  uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> [T: Value] {
    try .init(map { (try transform($0.key), $0.value) }, uniquingKeysWith: combine)
  }

  /// Transforms dictionary keys without modifying values.
  /// Drops (key, value) pairs where the transform results in a nil key.
  /// Deduplicates transformed keys.
  ///
  /// Example:
  /// ```
  /// ["one": 1, "two": 2, "three": 3, "": 4].compactMapKeys({ $0.first }, uniquingKeysWith: { max($0, $1) })
  /// // ["o": 1, "t": 3]
  /// ```
  ///
  /// - Parameters:
  ///   - transform: A closure that accepts each key of the dictionary as
  ///   its parameter and returns an optional transformed key of the same or of a different type.
  ///   - combine: A closure that is called with the values for any duplicate
  ///   keys that are encountered. The closure returns the desired value for
  ///   the final dictionary.
  /// - Returns: A dictionary containing the non-nil transformed keys and values of this dictionary.
  func compactMapKeys<T>(_ transform: (Key) throws -> T?,
                         uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> [T: Value] {
    try .init(compactMap { (try transform($0.key), $0.value) as? (T, Value) }, uniquingKeysWith: combine)
  }
}
