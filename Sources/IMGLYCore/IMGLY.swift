import Foundation

/// Wrapper for `IMGLY` compatible types. This type provides an extension point for
/// convenience methods in `IMGLY*` modules.
public struct IMGLY<Wrapped> {
  @_spi(Internal) public let wrapped: Wrapped
  @_spi(Internal) public init(_ wrapped: Wrapped) {
    self.wrapped = wrapped
  }
}

/// Represents an object type that is compatible with ``IMGLY``. You can use ``imgly`` property to get a
/// value in the namespace of `IMGLY*` modules.
public protocol IMGLYCompatible {
  /// Type that is being wrapped.
  associatedtype CompatibleType

  /// Gets a namespace holder for ``IMGLY`` compatible types.
  static var imgly: IMGLY<CompatibleType>.Type { get set }
  /// Gets a namespace holder for ``IMGLY`` compatible types.
  var imgly: IMGLY<CompatibleType> { get set }
}

public extension IMGLYCompatible {
  /// Gets a namespace holder for `IMGLY` compatible types.
  static var imgly: IMGLY<Self>.Type {
    get { IMGLY<Self>.self }
    set {} // swiftlint:disable:this unused_setter_value
  }

  /// Gets a namespace holder for ``IMGLY`` compatible types.
  var imgly: IMGLY<Self> {
    get { IMGLY(self) }
    set {} // swiftlint:disable:this unused_setter_value
  }
}
