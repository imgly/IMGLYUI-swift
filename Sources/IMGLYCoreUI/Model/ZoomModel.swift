import SwiftUI

@_spi(Internal) public class ZoomModel {
  @_spi(Internal) public var defaultZoomLevel: Float?
  @_spi(Internal) public var defaultInsets: EdgeInsets = .init()

  @_spi(Internal) public init(defaultZoomLevel: Float? = nil, defaultInsets: EdgeInsets = .init()) {
    self.defaultZoomLevel = defaultZoomLevel
    self.defaultInsets = defaultInsets
  }
}
