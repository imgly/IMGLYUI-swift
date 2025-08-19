import CoreGraphics
@_spi(Internal) import IMGLYCore
import IMGLYEngine
import UIKit

@_spi(Internal) public extension RGBA {
  func color() throws -> CGColor {
    let components = [r, g, b, a].map { CGFloat($0) }
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let color = CGColor(colorSpace: colorSpace, components: components) else {
      throw Error(errorDescription: "Could not convert sRGB RGBA to CGColor.")
    }

    return color
  }

  func changeBrightness(by delta: CGFloat) throws -> RGBA {
    guard let currentHSBA = try color().hsba else {
      throw Error(errorDescription: "No HSBA value found.")
    }

    let adjustment = currentHSBA
      .brightness > 0.5 ? max(currentHSBA.brightness - delta, 0) : min(currentHSBA.brightness + delta, 1)
    let new = HSBA(
      hue: currentHSBA.hue,
      saturation: currentHSBA.saturation,
      brightness: adjustment,
      alpha: currentHSBA.alpha,
    )
    return try UIColor(hsba: new).cgColor.rgba()
  }
}
