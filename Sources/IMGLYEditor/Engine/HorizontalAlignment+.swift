@_spi(Internal) import IMGLYEngine
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public extension HorizontalAlignment {
  init(_ alignment: HorizontalTextAlignment) {
    switch alignment {
    case .left: self = .left
    case .center: self = .center
    case .right: self = .right
    case .justify: self = .justify
    case .auto: self = .auto
    // Only for a value a newer engine adds. Every known case is listed, so the next
    // addition is a warning here instead of a silent fall to `.left`.
    @unknown default: self = .left
    }
  }
}
