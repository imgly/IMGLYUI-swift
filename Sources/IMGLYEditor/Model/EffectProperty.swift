import Foundation
@_spi(Internal) import IMGLYCore
import SwiftUI

struct EffectProperty: Identifiable {
  enum Value {
    case float(range: ClosedRange<Float>, defaultValue: Float?)
    case color(supportsOpacity: Bool, defaultValue: CGColor?)
  }

  let label: LocalizedStringKey
  let value: Value
  let property: Property
  let id: Interactor.BlockID?

  static func properties(for filter: Filter, and selection: Interactor.BlockID?) -> [EffectProperty] {
    let isLUT = filter == .lut
    let property = isLUT ? "lut_filter" : "duotone_filter"
    let intensity = EffectProperty(
      label: "Intensity",
      value: .float(range: isLUT ? 0 ... 1 : -1 ... 1, defaultValue: 1),
      property: .raw("effect/\(property)/intensity"),
      id: selection
    )
    return [intensity]
  }

  static func properties(for blur: Interactor.BlurType, and selection: Interactor.BlockID?) -> [EffectProperty] {
    switch blur {
    case .radial:
      [EffectProperty(
        label: "Intensity",
        value: .float(range: 0 ... 100, defaultValue: 30),
        property: .key(.blurRadialBlurRadius),
        id: selection
      ),
      EffectProperty(
        label: "Size of Gradient",
        value: .float(range: 0 ... 1000, defaultValue: 50),
        property: .key(.blurRadialGradientRadius),
        id: selection
      ),
      EffectProperty(
        label: "Size of non-blurred Area",
        value: .float(range: 0 ... 1000, defaultValue: 75),
        property: .key(.blurRadialRadius),
        id: selection
      ),
      EffectProperty(
        label: "Point - X",
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurRadialX),
        id: selection
      ),
      EffectProperty(
        label: "Point - Y",
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurRadialY),
        id: selection
      )]
    case .mirrored:
      [EffectProperty(
        label: "Intensity",
        value: .float(range: 0 ... 100, defaultValue: 30),
        property: .key(.blurMirroredBlurRadius),
        id: selection
      ),
      EffectProperty(
        label: "Size of Gradient",
        value: .float(range: 0 ... 1000, defaultValue: 50),
        property: .key(.blurMirroredGradientSize),
        id: selection
      ),
      EffectProperty(
        label: "Size of non-blurred Area",
        value: .float(range: 0 ... 1000, defaultValue: 75),
        property: .key(.blurMirroredSize),
        id: selection
      ),
      EffectProperty(
        label: "Point 1 - X",
        value: .float(range: 0 ... 1, defaultValue: 0),
        property: .key(.blurMirroredX1),
        id: selection
      ),
      EffectProperty(
        label: "Point 1 - Y",
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurMirroredY1),
        id: selection
      ),
      EffectProperty(
        label: "Point 2 - X",
        value: .float(range: 0 ... 1, defaultValue: 1),
        property: .key(.blurMirroredX2),
        id: selection
      ),
      EffectProperty(
        label: "Point 2 - Y",
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurMirroredY2),
        id: selection
      )]
    case .uniform:
      [EffectProperty(
        label: "Intensity",
        value: .float(range: 0 ... 1, defaultValue: 0.2),
        property: .key(.blurUniformIntensity),
        id: selection
      )]
    case .linear:
      [EffectProperty(
        label: "Intensity",
        value: .float(range: 0 ... 100, defaultValue: 30),
        property: .key(.blurLinearBlurRadius),
        id: selection
      ),
      EffectProperty(
        label: "Point 1 - X",
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurLinearX1),
        id: selection
      ),
      EffectProperty(
        label: "Point 1 - Y",
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurLinearY1),
        id: selection
      ),
      EffectProperty(
        label: "Point 2 - X",
        value: .float(range: 0 ... 1, defaultValue: 1),
        property: .key(.blurLinearX2),
        id: selection
      ),
      EffectProperty(
        label: "Point 2 - Y",
        value: .float(range: 0 ... 1, defaultValue: 1),
        property: .key(.blurLinearY2),
        id: selection
      )]
    default:
      []
    }
  }

  // swiftlint:disable cyclomatic_complexity
  static func properties(for effect: Interactor.EffectType, and selection: Interactor.BlockID?) -> [EffectProperty] {
    switch effect {
    case .pixelize:
      [
        EffectProperty(
          label: "Horizontal Count",
          value: .float(range: 5 ... 50, defaultValue: 20),
          property: .key(.effectPixelizeHorizontalPixelSize),
          id: selection
        ),
        EffectProperty(
          label: "Vertical Count",
          value: .float(range: 5 ... 50, defaultValue: 20),
          property: .key(.effectPixelizeVerticalPixelSize),
          id: selection
        ),
      ]
    case .radialPixel:
      [
        EffectProperty(
          label: "Radius per Row",
          value: .float(range: 0.05 ... 1, defaultValue: 0.1),
          property: .key(.effectRadialPixelRadius),
          id: selection
        ),
        EffectProperty(
          label: "Size per Row",
          value: .float(range: 0.01 ... 1, defaultValue: 0.01),
          property: .key(.effectRadialPixelSegments),
          id: selection
        ),
      ]
    case .crossCut:
      [
        EffectProperty(
          label: "Horizontal Cuts",
          value: .float(range: 1 ... 10, defaultValue: 5),
          property: .key(.effectCrossCutSlices),
          id: selection
        ),
        EffectProperty(
          label: "Horizontal Offset",
          value: .float(range: 0 ... 1, defaultValue: 0.07),
          property: .key(.effectCrossCutOffset),
          id: selection
        ),
        EffectProperty(
          label: "Vertical Offset",
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectCrossCutSpeedV),
          id: selection
        ),
        EffectProperty(
          label: "Variation",
          value: .float(range: 0 ... 1, defaultValue: 1),
          property: .key(.effectCrossCutTime),
          id: selection
        ),
      ]
    case .liquid:
      [
        EffectProperty(
          label: "Intensity",
          value: .float(range: 0 ... 1, defaultValue: 0.06),
          property: .key(.effectLiquidAmount),
          id: selection
        ),
        EffectProperty(
          label: "Scale",
          value: .float(range: 0 ... 1, defaultValue: 0.62),
          property: .key(.effectLiquidScale),
          id: selection
        ),
        EffectProperty(
          label: "Variation",
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectLiquidTime),
          id: selection
        ),
      ]
    case .outliner:
      [
        EffectProperty(
          label: "Intensity",
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectOutlinerAmount),
          id: selection
        ),
        EffectProperty(
          label: "Blending",
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectOutlinerPassthrough),
          id: selection
        ),
      ]
    case .dotPattern:
      [
        EffectProperty(
          label: "Number of Dots",
          value: .float(range: 1 ... 80, defaultValue: 30),
          property: .key(.effectDotPatternDots),
          id: selection
        ),
        EffectProperty(
          label: "Size of Dots",
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectDotPatternSize),
          id: selection
        ),
        EffectProperty(
          label: "Global Blur",
          value: .float(range: 0 ... 1, defaultValue: 0.3),
          property: .key(.effectDotPatternBlur),
          id: selection
        ),
      ]
    case .posterize:
      [EffectProperty(
        label: "Number of Levels",
        value: .float(range: 1 ... 15, defaultValue: 3),
        property: .key(.effectPosterizeLevels),
        id: selection
      )]
    case .tvGlitch:
      [
        EffectProperty(
          label: "Rough Distortion",
          value: .float(range: 0 ... 10, defaultValue: 3),
          property: .key(.effectTvGlitchDistortion),
          id: selection
        ),
        EffectProperty(
          label: "Fine Distortion",
          value: .float(range: 0 ... 5, defaultValue: 1),
          property: .key(.effectTvGlitchDistortion2),
          id: selection
        ),
        EffectProperty(
          label: "Variance",
          value: .float(range: 0 ... 5, defaultValue: 2),
          property: .key(.effectTvGlitchSpeed),
          id: selection
        ),
        EffectProperty(
          label: "Vertical Offset",
          value: .float(range: 0 ... 3, defaultValue: 1),
          property: .key(.effectTvGlitchRollSpeed),
          id: selection
        ),
      ]
    case .halfTone:
      [
        EffectProperty(
          label: "Angle of Pattern",
          value: .float(range: 0 ... 1, defaultValue: 0),
          property: .key(.effectHalfToneAngle),
          id: selection
        ),
        EffectProperty(
          label: "Scale of Pattern",
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectHalfToneScale),
          id: selection
        ),
      ]
    case .linocut:
      [EffectProperty(
        label: "Scale of Pattern",
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.effectLinocutScale),
        id: selection
      )]
    case .shifter:
      [
        EffectProperty(
          label: "Distance",
          value: .float(range: 0 ... 1, defaultValue: 0.05),
          property: .key(.effectShifterAmount),
          id: selection
        ),
        EffectProperty(
          label: "Shift Direction",
          value: .float(range: 0 ... 6.3, defaultValue: 0.3),
          property: .key(.effectShifterAngle),
          id: selection
        ),
      ]
    case .mirror:
      [EffectProperty(
        label: "Mirrored Side",
        value: .float(range: 0 ... 3, defaultValue: 1),
        property: .key(.effectMirrorSide),
        id: selection
      )]
    case .glow:
      [
        EffectProperty(
          label: "Bloom",
          value: .float(range: 0 ... 10, defaultValue: 4),
          property: .key(.effectGlowSize),
          id: selection
        ),
        EffectProperty(
          label: "Intensity",
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectGlowAmount),
          id: selection
        ),
        EffectProperty(
          label: "Darkening",
          value: .float(range: 0 ... 1, defaultValue: 0.3),
          property: .key(.effectGlowDarkness),
          id: selection
        ),
      ]
    case .vignette:
      [
        EffectProperty(
          label: "Size",
          value: .float(range: 0 ... 5, defaultValue: 1),
          property: .key(.effectVignetteOffset),
          id: selection
        ),
        EffectProperty(
          label: "Color",
          value: .float(range: 0 ... 1, defaultValue: 1),
          property: .key(.effectVignetteDarkness),
          id: selection
        ),
      ]
    case .tiltShift:
      [
        EffectProperty(
          label: "Intensity",
          value: .float(range: 0 ... 0.02, defaultValue: 0.016),
          property: .key(.effectTiltShiftAmount),
          id: selection
        ),
        EffectProperty(
          label: "Position",
          value: .float(range: 0 ... 1, defaultValue: 0.4),
          property: .key(.effectTiltShiftPosition),
          id: selection
        ),
      ]
    case .extrudeBlur:
      [EffectProperty(
        label: "Intensity",
        value: .float(range: 0 ... 1, defaultValue: 0.2),
        property: .key(.effectExtrudeBlurAmount),
        id: selection
      )]
    case .recolor:
      [
        EffectProperty(
          label: "Source Color",
          value: .color(supportsOpacity: false, defaultValue: .imgly.black),
          property: .key(.effectRecolorFromColor),
          id: selection
        ),
        EffectProperty(
          label: "Target Color",
          value: .color(supportsOpacity: false, defaultValue: .imgly.black),
          property: .key(.effectRecolorToColor),
          id: selection
        ),
        EffectProperty(
          label: "Color Match",
          value: .float(range: 0 ... 1, defaultValue: 0.4),
          property: .key(.effectRecolorColorMatch),
          id: selection
        ),
        EffectProperty(
          label: "Brightness Match",
          value: .float(range: 0 ... 1, defaultValue: 1),
          property: .key(.effectRecolorBrightnessMatch),
          id: selection
        ),
        EffectProperty(
          label: "Smoothness",
          value: .float(range: 0 ... 1, defaultValue: 0.08),
          property: .key(.effectRecolorSmoothness),
          id: selection
        ),
      ]
    case .greenScreen:
      [
        EffectProperty(
          label: "Source Color",
          value: .color(supportsOpacity: false, defaultValue: .imgly.black),
          property: .key(.effectGreenScreenFromColor),
          id: selection
        ),
        EffectProperty(
          label: "Color Match",
          value: .float(range: 0 ... 1, defaultValue: 0.4),
          property: .key(.effectGreenScreenColorMatch),
          id: selection
        ),
        EffectProperty(
          label: "Smoothness",
          value: .float(range: 0 ... 1, defaultValue: 0.08),
          property: .key(.effectGreenScreenSmoothness),
          id: selection
        ),
        EffectProperty(
          label: "Spill",
          value: .float(range: 0 ... 1, defaultValue: 0),
          property: .key(.effectGreenScreenSpill),
          id: selection
        ),
      ]
    default:
      []
    }
  }
  // swiftlint:enable cyclomatic_complexity
}
