@_spi(Internal) import IMGLYEngine
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public extension HorizontalAlignment {
  init(_ alignment: HorizontalTextAlignment) {
    switch alignment {
    case .left: self = .left
    case .center: self = .center
    case .right: self = .right
    case .auto: self = .auto
    @unknown default: self = .left
    }
  }
}
