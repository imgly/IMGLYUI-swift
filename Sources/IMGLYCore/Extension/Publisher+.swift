import Combine

@_spi(Internal) public extension Publisher where Self.Failure == Never {
  /// Assigns a published value to a given object's keypath, without creating a reference
  /// cycle like `assign(to:on:)` does.
  func assignNoRetain<Root>(
    to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
    on object: Root
  ) -> AnyCancellable where Root: AnyObject {
    sink { [weak object] value in
      object?[keyPath: keyPath] = value
    }
  }
}
