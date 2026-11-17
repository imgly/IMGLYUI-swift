import CoreGraphics
import IMGLYEngine

@_spi(Internal) public extension Engine {
  /// The sRGB color that the canvas draws a swatch color with.
  ///
  /// `IMGLYEngine.Color.cgColor` gives a CMYK color in `CGColorSpace.genericCMYK`, which is not the profile the canvas
  /// converts with. So a CMYK color converts through the engine, and every other color is returned as it is. While the
  /// CMYK profile loads, or after it failed to load, the canvas draws CMYK by a formula, so the swatch uses it too.
  /// Draw the result only: a binding that writes back must keep the CMYK color.
  func displayColor(_ color: CGColor) -> CGColor {
    // `IMGLYEngine.Color.cgColor` passes the tint as the alpha component.
    guard color.colorSpace?.name == CGColorSpace.genericCMYK, let components = color.components,
          components.count == 5 else {
      return color
    }
    let (c, m, y, k, tint) = (Float(components[0]), Float(components[1]), Float(components[2]), Float(components[3]),
                              Float(components[4]))
    let converted: IMGLYEngine.Color
    do {
      converted = try editor.convertColorToColorSpace(color: .cmyk(c: c, m: m, y: y, k: k, tint: tint),
                                                      colorSpace: .sRGB)
    } catch let error as EngineError where Self.profileErrorCodes.contains(error.code) {
      // `naiveCMYKToSRGB` in the engine's ColorManagementService.
      let ink = { (component: Float) in min(max(component, 0), 1) * min(max(tint, 0), 1) }
      let key = 1 - ink(k)
      converted = .rgba(r: (1 - ink(c)) * key, g: (1 - ink(m)) * key, b: (1 - ink(y)) * key, a: 1)
    } catch {
      // A swatch has no way to report an error, so it keeps the color it had before the conversion.
      return color
    }
    return converted.cgColor ?? color
  }

  /// The codes of a conversion that fails only because the CMYK profile is loading or failed to load.
  private static let profileErrorCodes: Set<String> = [
    EngineErrorCode.colorProfileNotLoaded.rawValue,
    EngineErrorCode.colorProfileMissing.rawValue,
  ]
}
