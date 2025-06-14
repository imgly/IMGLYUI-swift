import SwiftUI

@_spi(Internal) public struct ZoomModel {
  @_spi(Internal) public var defaultZoomLevel: Float?
  @_spi(Internal) public var defaultInsets: EdgeInsets
  @_spi(Internal) public var defaultPadding: CGFloat
  @_spi(Internal) public var padding: CGFloat
  @_spi(Internal) public var canvasHeight: CGFloat

  @_spi(Internal) public init(defaultZoomLevel: Float? = nil,
                              defaultInsets: EdgeInsets = .init(),
                              defaultPadding: CGFloat = 0,
                              padding: CGFloat = 0,
                              canvasHeight: CGFloat = 0) {
    self.defaultZoomLevel = defaultZoomLevel
    self.defaultInsets = defaultInsets
    self.defaultPadding = defaultPadding
    self.padding = padding
    self.canvasHeight = canvasHeight
  }
}
