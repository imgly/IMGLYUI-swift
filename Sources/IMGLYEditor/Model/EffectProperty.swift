import Foundation
@_spi(Internal) import IMGLYCore
import SwiftUI

struct EffectProperty: Identifiable {
  let label: LocalizedStringKey
  let range: ClosedRange<Float>
  let property: Property
  let id: Interactor.BlockID?
  let defaultValue: Float?

  static func properties(for filter: Filter, and selection: Interactor.BlockID?) -> [EffectProperty] {
    let isLUT = filter == .lut
    let property = isLUT ? "lut_filter" : "duotone_filter"
    let intensity = EffectProperty(
      label: "Intensity",
      range: isLUT ? 0 ... 1 : -1 ... 1,
      property: .raw("effect/\(property)/intensity"),
      id: selection,
      defaultValue: 1
    )
    return [intensity]
  }

  static func properties(for blur: Interactor.BlurType, and selection: Interactor.BlockID?) -> [EffectProperty] {
    switch blur {
    case .radial:
      return [EffectProperty(
        label: "Intensity",
        range: 0 ... 100,
        property: .key(.blurRadialBlurRadius),
        id: selection,
        defaultValue: 30
      ),
      EffectProperty(
        label: "Size of Gradient",
        range: 0 ... 1000,
        property: .key(.blurRadialGradientRadius),
        id: selection,
        defaultValue: 50
      ),
      EffectProperty(
        label: "Size of non-blurred Area",
        range: 0 ... 1000,
        property: .key(.blurRadialRadius),
        id: selection,
        defaultValue: 75
      ),
      EffectProperty(
        label: "Point - X",
        range: 0 ... 1,
        property: .key(.blurRadialX),
        id: selection,
        defaultValue: 0.5
      ),
      EffectProperty(
        label: "Point - Y",
        range: 0 ... 1,
        property: .key(.blurRadialY),
        id: selection,
        defaultValue: 0.5
      )]
    case .mirrored:
      return [EffectProperty(
        label: "Intensity",
        range: 0 ... 100,
        property: .key(.blurMirroredBlurRadius),
        id: selection,
        defaultValue: 30
      ),
      EffectProperty(
        label: "Size of Gradient",
        range: 0 ... 1000,
        property: .key(.blurMirroredGradientSize),
        id: selection,
        defaultValue: 50
      ),
      EffectProperty(
        label: "Size of non-blurred Area",
        range: 0 ... 1000,
        property: .key(.blurMirroredSize),
        id: selection,
        defaultValue: 75
      ),
      EffectProperty(
        label: "Point 1 - X",
        range: 0 ... 1,
        property: .key(.blurMirroredX1),
        id: selection,
        defaultValue: 0
      ),
      EffectProperty(
        label: "Point 1 - Y",
        range: 0 ... 1,
        property: .key(.blurMirroredY1),
        id: selection,
        defaultValue: 0.5
      ),
      EffectProperty(
        label: "Point 2 - X",
        range: 0 ... 1,
        property: .key(.blurMirroredX2),
        id: selection,
        defaultValue: 1
      ),
      EffectProperty(
        label: "Point 2 - Y",
        range: 0 ... 1,
        property: .key(.blurMirroredY2),
        id: selection,
        defaultValue: 0.5
      )]
    case .uniform:
      return [EffectProperty(
        label: "Intensity",
        range: 0 ... 1,
        property: .key(.blurUniformIntensity),
        id: selection,
        defaultValue: 0.2
      )]
    case .linear:
      return [EffectProperty(
        label: "Intensity",
        range: 0 ... 100,
        property: .key(.blurLinearBlurRadius),
        id: selection,
        defaultValue: 30
      ),
      EffectProperty(
        label: "Point 1 - X",
        range: 0 ... 1,
        property: .key(.blurLinearX1),
        id: selection,
        defaultValue: 0.5
      ),
      EffectProperty(
        label: "Point 1 - Y",
        range: 0 ... 1,
        property: .key(.blurLinearY1),
        id: selection,
        defaultValue: 0.5
      ),
      EffectProperty(
        label: "Point 2 - X",
        range: 0 ... 1,
        property: .key(.blurLinearX2),
        id: selection,
        defaultValue: 1
      ),
      EffectProperty(
        label: "Point 2 - Y",
        range: 0 ... 1,
        property: .key(.blurLinearY2),
        id: selection,
        defaultValue: 1
      )]
    default:
      return []
    }
  }

  // swiftlint:disable cyclomatic_complexity
  static func properties(for effect: Interactor.EffectType, and selection: Interactor.BlockID?) -> [EffectProperty] {
    switch effect {
    case .pixelize:
      return [
        EffectProperty(
          label: "Horizontal Count",
          range: 5 ... 50,
          property: .key(.effectPixelizeHorizontalPixelSize),
          id: selection,
          defaultValue: 20
        ),
        EffectProperty(
          label: "Vertical Count",
          range: 5 ... 50,
          property: .key(.effectPixelizeVerticalPixelSize),
          id: selection,
          defaultValue: 20
        )
      ]
    case .radialPixel:
      return [
        EffectProperty(
          label: "Radius per Row",
          range: 0.05 ... 1,
          property: .key(.effectRadialPixelRadius),
          id: selection,
          defaultValue: 0.1
        ),
        EffectProperty(
          label: "Size per Row",
          range: 0.01 ... 1,
          property: .key(.effectRadialPixelSegments),
          id: selection,
          defaultValue: 0.01
        )
      ]
    case .crossCut:
      return [
        EffectProperty(label: "Horizontal Cuts", range: 1 ... 10, property: .key(.effectCrossCutSlices), id: selection,
                       defaultValue: 5),
        EffectProperty(
          label: "Horizontal Offset",
          range: 0 ... 1,
          property: .key(.effectCrossCutOffset),
          id: selection,
          defaultValue: 0.07
        ),
        EffectProperty(
          label: "Vertical Offset",
          range: 0 ... 1,
          property: .key(.effectCrossCutSpeedV),
          id: selection,
          defaultValue: 0.5
        ),
        EffectProperty(
          label: "Variation",
          range: 0 ... 1,
          property: .key(.effectCrossCutTime),
          id: selection,
          defaultValue: 1
        )
      ]
    case .liquid:
      return [
        EffectProperty(label: "Intensity", range: 0 ... 1, property: .key(.effectLiquidAmount), id: selection,
                       defaultValue: 0.06),
        EffectProperty(
          label: "Scale",
          range: 0 ... 1,
          property: .key(.effectLiquidScale),
          id: selection,
          defaultValue: 0.62
        ),
        EffectProperty(
          label: "Variation",
          range: 0 ... 1,
          property: .key(.effectLiquidTime),
          id: selection,
          defaultValue: 0.5
        )
      ]
    case .outliner:
      return [
        EffectProperty(label: "Intensity", range: 0 ... 1, property: .key(.effectOutlinerAmount), id: selection,
                       defaultValue: 0.5),
        EffectProperty(
          label: "Blending",
          range: 0 ... 1,
          property: .key(.effectOutlinerPassthrough),
          id: selection,
          defaultValue: 0.5
        )
      ]
    case .dotPattern:
      return [
        EffectProperty(label: "Number of Dots", range: 1 ... 80, property: .key(.effectDotPatternDots), id: selection,
                       defaultValue: 30),
        EffectProperty(
          label: "Size of Dots",
          range: 0 ... 1,
          property: .key(.effectDotPatternSize),
          id: selection,
          defaultValue: 0.5
        ),
        EffectProperty(
          label: "Global Blur",
          range: 0 ... 1,
          property: .key(.effectDotPatternBlur),
          id: selection,
          defaultValue: 0.3
        )
      ]
    case .posterize:
      return [EffectProperty(
        label: "Number of Levels",
        range: 1 ... 15,
        property: .key(.effectPosterizeLevels),
        id: selection,
        defaultValue: 3
      )]
    case .tvGlitch:
      return [
        EffectProperty(
          label: "Rough Distortion",
          range: 0 ... 10,
          property: .key(.effectTvGlitchDistortion),
          id: selection,
          defaultValue: 3
        ),
        EffectProperty(
          label: "Fine Distortion",
          range: 0 ... 5,
          property: .key(.effectTvGlitchDistortion2),
          id: selection,
          defaultValue: 1
        ),
        EffectProperty(
          label: "Variance",
          range: 0 ... 5,
          property: .key(.effectTvGlitchSpeed),
          id: selection,
          defaultValue: 2
        ),
        EffectProperty(
          label: "Vertical Offset",
          range: 0 ... 3,
          property: .key(.effectTvGlitchRollSpeed),
          id: selection,
          defaultValue: 1
        )
      ]
    case .halfTone:
      return [
        EffectProperty(label: "Angle of Pattern", range: 0 ... 1, property: .key(.effectHalfToneAngle), id: selection,
                       defaultValue: 0),
        EffectProperty(
          label: "Scale of Pattern",
          range: 0 ... 1,
          property: .key(.effectHalfToneScale),
          id: selection,
          defaultValue: 0.5
        )
      ]
    case .linocut:
      return [EffectProperty(
        label: "Scale of Pattern",
        range: 0 ... 1,
        property: .key(.effectLinocutScale),
        id: selection,
        defaultValue: 0.5
      )]
    case .shifter:
      return [
        EffectProperty(label: "Distance", range: 0 ... 1, property: .key(.effectShifterAmount), id: selection,
                       defaultValue: 0.05),
        EffectProperty(
          label: "Shift Direction",
          range: 0 ... 6.3,
          property: .key(.effectShifterAngle),
          id: selection,
          defaultValue: 0.3
        )
      ]
    case .mirror:
      return [EffectProperty(label: "Mirrored Side", range: 0 ... 3, property: .key(.effectMirrorSide), id: selection,
                             defaultValue: 1)]
    case .glow:
      return [
        EffectProperty(
          label: "Bloom",
          range: 0 ... 10,
          property: .key(.effectGlowSize),
          id: selection,
          defaultValue: 4
        ),
        EffectProperty(
          label: "Intensity",
          range: 0 ... 1,
          property: .key(.effectGlowAmount),
          id: selection,
          defaultValue: 0.5
        ),
        EffectProperty(
          label: "Darkening",
          range: 0 ... 1,
          property: .key(.effectGlowDarkness),
          id: selection,
          defaultValue: 0.3
        )
      ]
    case .vignette:
      return [
        EffectProperty(label: "Size", range: 0 ... 5, property: .key(.effectVignetteOffset), id: selection,
                       defaultValue: 1),
        EffectProperty(
          label: "Color",
          range: 0 ... 1,
          property: .key(.effectVignetteDarkness),
          id: selection,
          defaultValue: 1
        )
      ]
    case .tiltShift:
      return [
        EffectProperty(label: "Intensity", range: 0 ... 0.02, property: .key(.effectTiltShiftAmount), id: selection,
                       defaultValue: 0.016),
        EffectProperty(
          label: "Position",
          range: 0 ... 1,
          property: .key(.effectTiltShiftPosition),
          id: selection,
          defaultValue: 0.4
        )
      ]
    case .extrudeBlur:
      return [EffectProperty(
        label: "Intensity",
        range: 0 ... 1,
        property: .key(.effectExtrudeBlurAmount),
        id: selection,
        defaultValue: 0.2
      )]
    default:
      return []
    }
  }
  // swiftlint:enable cyclomatic_complexity
}
