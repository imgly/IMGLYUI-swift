import SwiftUI

@_spi(Internal) public struct Geometry: Equatable, @unchecked Sendable {
  @_spi(Internal) public init(_ proxy: GeometryProxy, _ coordinateSpace: CoordinateSpace) {
    frame = proxy.frame(in: coordinateSpace)
    safeAreaInsets = proxy.safeAreaInsets
    self.coordinateSpace = coordinateSpace
  }

  @_spi(Internal) public let frame: CGRect
  @_spi(Internal) public let safeAreaInsets: EdgeInsets
  @_spi(Internal) public let coordinateSpace: CoordinateSpace

  // Adds the `safeAreaInsets` to `frame.size`.
  @_spi(Internal) public var size: CGSize {
    CGSize(width: frame.width + safeAreaInsets.leading + safeAreaInsets.trailing,
           height: frame.height + safeAreaInsets.top + safeAreaInsets.bottom)
  }
}
