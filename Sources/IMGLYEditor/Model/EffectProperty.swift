import Foundation
@_spi(Internal) import IMGLYCore
import SwiftUI

struct EffectProperty: Identifiable {
  enum Value {
    case float(range: ClosedRange<Float>, defaultValue: Float?)
    case color(supportsOpacity: Bool, defaultValue: CGColor?)
  }

  let label: LocalizedStringResource
  let value: Value
  let property: Property
  let id: Interactor.BlockID?

  static func properties(for filter: Filter, and selection: Interactor.BlockID?) -> [EffectProperty] {
    let isLUT = filter == .lut
    let property = isLUT ? "lut_filter" : "duotone_filter"
    let intensity = EffectProperty(
      label: .imgly.localized("ly_img_editor_sheet_filter_label_intensity"),
      value: .float(range: isLUT ? 0 ... 1 : -1 ... 1, defaultValue: 1),
      property: .raw("effect/\(property)/intensity"),
      id: selection,
    )
    return [intensity]
  }

  static func properties(for blur: Interactor.BlurType, and selection: Interactor.BlockID?) -> [EffectProperty] {
    switch blur {
    case .radial:
      [EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_intensity"),
        value: .float(range: 0 ... 100, defaultValue: 30),
        property: .key(.blurRadialBlurRadius),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_gradient_size"),
        value: .float(range: 0 ... 1000, defaultValue: 50),
        property: .key(.blurRadialGradientRadius),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_non_blurred_size"),
        value: .float(range: 0 ... 1000, defaultValue: 75),
        property: .key(.blurRadialRadius),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_point_x"),
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurRadialX),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_point_y"),
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurRadialY),
        id: selection,
      )]
    case .mirrored:
      [EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_intensity"),
        value: .float(range: 0 ... 100, defaultValue: 30),
        property: .key(.blurMirroredBlurRadius),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_gradient_size"),
        value: .float(range: 0 ... 1000, defaultValue: 50),
        property: .key(.blurMirroredGradientSize),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_non_blurred_size"),
        value: .float(range: 0 ... 1000, defaultValue: 75),
        property: .key(.blurMirroredSize),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_point_x1"),
        value: .float(range: 0 ... 1, defaultValue: 0),
        property: .key(.blurMirroredX1),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_point_y1"),
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurMirroredY1),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_point_x2"),
        value: .float(range: 0 ... 1, defaultValue: 1),
        property: .key(.blurMirroredX2),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_point_y2"),
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurMirroredY2),
        id: selection,
      )]
    case .uniform:
      [EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_intensity"),
        value: .float(range: 0 ... 1, defaultValue: 0.2),
        property: .key(.blurUniformIntensity),
        id: selection,
      )]
    case .linear:
      [EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_intensity"),
        value: .float(range: 0 ... 100, defaultValue: 30),
        property: .key(.blurLinearBlurRadius),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_point_x1"),
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurLinearX1),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_point_y1"),
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.blurLinearY1),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_point_x2"),
        value: .float(range: 0 ... 1, defaultValue: 1),
        property: .key(.blurLinearX2),
        id: selection,
      ),
      EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_blur_label_point_y2"),
        value: .float(range: 0 ... 1, defaultValue: 1),
        property: .key(.blurLinearY2),
        id: selection,
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
          label: .imgly.localized("ly_img_editor_sheet_effect_label_pixelize_horizontal_count"),
          value: .float(range: 5 ... 50, defaultValue: 20),
          property: .key(.effectPixelizeHorizontalPixelSize),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_pixelize_vertical_count"),
          value: .float(range: 5 ... 50, defaultValue: 20),
          property: .key(.effectPixelizeVerticalPixelSize),
          id: selection,
        ),
      ]
    case .radialPixel:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_radial_pixel_row_pixels"),
          value: .float(range: 0.05 ... 1, defaultValue: 0.1),
          property: .key(.effectRadialPixelRadius),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_radial_pixel_row_size"),
          value: .float(range: 0.01 ... 1, defaultValue: 0.01),
          property: .key(.effectRadialPixelSegments),
          id: selection,
        ),
      ]
    case .crossCut:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_cross_cut_horizontal_cuts"),
          value: .float(range: 1 ... 10, defaultValue: 5),
          property: .key(.effectCrossCutSlices),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_cross_cut_horizontal_offset"),
          value: .float(range: 0 ... 1, defaultValue: 0.07),
          property: .key(.effectCrossCutOffset),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_cross_cut_vertical_offset"),
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectCrossCutSpeedV),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_cross_cut_variation"),
          value: .float(range: 0 ... 1, defaultValue: 1),
          property: .key(.effectCrossCutTime),
          id: selection,
        ),
      ]
    case .liquid:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_liquid_intensity"),
          value: .float(range: 0 ... 1, defaultValue: 0.06),
          property: .key(.effectLiquidAmount),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_liquid_scale"),
          value: .float(range: 0 ... 1, defaultValue: 0.62),
          property: .key(.effectLiquidScale),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_liquid_variation"),
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectLiquidTime),
          id: selection,
        ),
      ]
    case .outliner:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_outliner_intensity"),
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectOutlinerAmount),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_outliner_blending"),
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectOutlinerPassthrough),
          id: selection,
        ),
      ]
    case .dotPattern:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_dot_pattern_dots"),
          value: .float(range: 1 ... 80, defaultValue: 30),
          property: .key(.effectDotPatternDots),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_dot_pattern_size"),
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectDotPatternSize),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_dot_pattern_blur"),
          value: .float(range: 0 ... 1, defaultValue: 0.3),
          property: .key(.effectDotPatternBlur),
          id: selection,
        ),
      ]
    case .posterize:
      [EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_effect_label_posterize_levels"),
        value: .float(range: 1 ... 15, defaultValue: 3),
        property: .key(.effectPosterizeLevels),
        id: selection,
      )]
    case .tvGlitch:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_tv_glitch_rough_distortion"),
          value: .float(range: 0 ... 10, defaultValue: 3),
          property: .key(.effectTvGlitchDistortion),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_tv_glitch_fine_distortion"),
          value: .float(range: 0 ... 5, defaultValue: 1),
          property: .key(.effectTvGlitchDistortion2),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_tv_glitch_variance"),
          value: .float(range: 0 ... 5, defaultValue: 2),
          property: .key(.effectTvGlitchSpeed),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_tv_glitch_vertical_offset"),
          value: .float(range: 0 ... 3, defaultValue: 1),
          property: .key(.effectTvGlitchRollSpeed),
          id: selection,
        ),
      ]
    case .halfTone:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_half_tone_angle"),
          value: .float(range: 0 ... 1, defaultValue: 0),
          property: .key(.effectHalfToneAngle),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_half_tone_scale"),
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectHalfToneScale),
          id: selection,
        ),
      ]
    case .linocut:
      [EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_effect_label_linocut_scale"),
        value: .float(range: 0 ... 1, defaultValue: 0.5),
        property: .key(.effectLinocutScale),
        id: selection,
      )]
    case .shifter:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_shifter_distance"),
          value: .float(range: 0 ... 1, defaultValue: 0.05),
          property: .key(.effectShifterAmount),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_shifter_direction"),
          value: .float(range: 0 ... 6.3, defaultValue: 0.3),
          property: .key(.effectShifterAngle),
          id: selection,
        ),
      ]
    case .mirror:
      [EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_effect_label_mirror_side"),
        value: .float(range: 0 ... 3, defaultValue: 1),
        property: .key(.effectMirrorSide),
        id: selection,
      )]
    case .glow:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_glow_bloom"),
          value: .float(range: 0 ... 10, defaultValue: 4),
          property: .key(.effectGlowSize),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_glow_intensity"),
          value: .float(range: 0 ... 1, defaultValue: 0.5),
          property: .key(.effectGlowAmount),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_glow_darkening"),
          value: .float(range: 0 ... 1, defaultValue: 0.3),
          property: .key(.effectGlowDarkness),
          id: selection,
        ),
      ]
    case .vignette:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_vignette_size"),
          value: .float(range: 0 ... 5, defaultValue: 1),
          property: .key(.effectVignetteOffset),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_vignette_color"),
          value: .float(range: 0 ... 1, defaultValue: 1),
          property: .key(.effectVignetteDarkness),
          id: selection,
        ),
      ]
    case .tiltShift:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_tilt_shift_intensity"),
          value: .float(range: 0 ... 0.02, defaultValue: 0.016),
          property: .key(.effectTiltShiftAmount),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_tilt_shift_position"),
          value: .float(range: 0 ... 1, defaultValue: 0.4),
          property: .key(.effectTiltShiftPosition),
          id: selection,
        ),
      ]
    case .extrudeBlur:
      [EffectProperty(
        label: .imgly.localized("ly_img_editor_sheet_effect_label_extrude_blur_intensity"),
        value: .float(range: 0 ... 1, defaultValue: 0.2),
        property: .key(.effectExtrudeBlurAmount),
        id: selection,
      )]
    case .recolor:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_recolor_source_color"),
          value: .color(supportsOpacity: false, defaultValue: .imgly.black),
          property: .key(.effectRecolorFromColor),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_recolor_target_color"),
          value: .color(supportsOpacity: false, defaultValue: .imgly.black),
          property: .key(.effectRecolorToColor),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_recolor_color_match"),
          value: .float(range: 0 ... 1, defaultValue: 0.4),
          property: .key(.effectRecolorColorMatch),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_recolor_brightness_match"),
          value: .float(range: 0 ... 1, defaultValue: 1),
          property: .key(.effectRecolorBrightnessMatch),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_recolor_smoothness"),
          value: .float(range: 0 ... 1, defaultValue: 0.08),
          property: .key(.effectRecolorSmoothness),
          id: selection,
        ),
      ]
    case .greenScreen:
      [
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_green_screen_source_color"),
          value: .color(supportsOpacity: false, defaultValue: .imgly.black),
          property: .key(.effectGreenScreenFromColor),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_green_screen_color_match"),
          value: .float(range: 0 ... 1, defaultValue: 0.4),
          property: .key(.effectGreenScreenColorMatch),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_green_screen_smoothness"),
          value: .float(range: 0 ... 1, defaultValue: 0.08),
          property: .key(.effectGreenScreenSmoothness),
          id: selection,
        ),
        EffectProperty(
          label: .imgly.localized("ly_img_editor_sheet_effect_label_green_screen_spill"),
          value: .float(range: 0 ... 1, defaultValue: 0),
          property: .key(.effectGreenScreenSpill),
          id: selection,
        ),
      ]
    default:
      []
    }
  }
  // swiftlint:enable cyclomatic_complexity
}
