import Foundation

@_spi(Internal) public typealias Property = RawRepresentableKey<PropertyKey>

@_spi(Internal) public enum PropertyKey: String {
  case fillColorValue = "fill/color/value"
  case fillEnabled = "fill/enabled"
  case fillSolidColor = "fill/solid/color"
  case fillGradientColors = "fill/gradient/colors"

  case fillGradientLinearStartX = "fill/gradient/linear/startPointX"
  case fillGradientLinearStartY = "fill/gradient/linear/startPointY"
  case fillGradientLinearEndX = "fill/gradient/linear/endPointX"
  case fillGradientLinearEndY = "fill/gradient/linear/endPointY"

  case fillImageImageFileURI = "fill/image/imageFileURI"

  case strokeEnabled = "stroke/enabled"
  case strokeColor = "stroke/color"
  case strokeWidth = "stroke/width"
  case strokeStyle = "stroke/style"
  case strokePosition = "stroke/position"
  case strokeCornerGeometry = "stroke/cornerGeometry"

  case opacity

  case blendMode = "blend/mode"

  case heightMode = "height/mode"

  case lastFrameHeight = "lastFrame/height"

  case playbackPlaying = "playback/playing"

  case textFontFileURI = "text/fontFileUri"
  case textFontSize = "text/fontSize"
  case textHorizontalAlignment = "text/horizontalAlignment"
  case textLetterSpacing = "text/letterSpacing"
  case textLineHeight = "text/lineHeight"
  case textVerticalAlignment = "text/verticalAlignment"
  case textClipLinesOutsideOfFrame = "text/clipLinesOutsideOfFrame"
  case textParagraphSpacing = "text/paragraphSpacing"

  case shapeStarPoints = "shape/star/points"
  case shapeStarInnerDiameter = "shape/star/innerDiameter"
  case shapePolygonSides = "shape/polygon/sides"
  case shapePolygonCornerRadius = "shape/polygon/cornerRadius"
  case shapeRectCornerRadiusTL = "shape/rect/cornerRadiusTL"
  case shapeRectCornerRadiusTR = "shape/rect/cornerRadiusTR"
  case shapeRectCornerRadiusBL = "shape/rect/cornerRadiusBL"
  case shapeRectCornerRadiusBR = "shape/rect/cornerRadiusBR"

  case sceneDesignUnit = "scene/designUnit"
  case sceneDPI = "scene/dpi"

  case stackAxis = "stack/axis"
  case stackSpacing = "stack/spacing"
  case stackSpacingInScreenspace = "stack/spacingInScreenspace"

  case cropRotation = "crop/rotation"
  case cropScaleRatio = "crop/scaleRatio"

  case type

  case filterLUTFileURI = "effect/lut_filter/lutFileURI"
  case filterLUTVerticalTileCount = "effect/lut_filter/verticalTileCount"
  case filterLUTHorizontalTileCount = "effect/lut_filter/horizontalTileCount"
  case filterLUTIntensity = "effect/lut_filter/intensity"
  case filterDuoToneLightColor = "effect/duotone_filter/lightColor"
  case filterDuoToneDarkColor = "effect/duotone_filter/darkColor"
  case filterDuoToneIntensity = "effect/duotone_filter/intensity"

  case blurRadialBlurRadius = "blur/radial/blurRadius"
  case blurRadialGradientRadius = "blur/radial/gradientRadius"
  case blurRadialRadius = "blur/radial/radius"
  case blurRadialX = "blur/radial/x"
  case blurRadialY = "blur/radial/y"

  case blurMirroredBlurRadius = "blur/mirrored/blurRadius"
  case blurMirroredGradientSize = "blur/mirrored/gradientSize"
  case blurMirroredSize = "blur/mirrored/size"
  case blurMirroredX1 = "blur/mirrored/x1"
  case blurMirroredY1 = "blur/mirrored/y1"
  case blurMirroredX2 = "blur/mirrored/x2"
  case blurMirroredY2 = "blur/mirrored/y2"

  case blurUniformIntensity = "blur/uniform/intensity"

  case blurLinearBlurRadius = "blur/linear/blurRadius"
  case blurLinearX1 = "blur/linear/x1"
  case blurLinearY1 = "blur/linear/y1"
  case blurLinearX2 = "blur/linear/x2"
  case blurLinearY2 = "blur/linear/y2"

  case effectPixelizeHorizontalPixelSize = "effect/pixelize/horizontalPixelSize"
  case effectPixelizeVerticalPixelSize = "effect/pixelize/verticalPixelSize"

  case effectRadialPixelRadius = "effect/radial_pixel/radius"
  case effectRadialPixelSegments = "effect/radial_pixel/segments"

  case effectCrossCutSlices = "effect/cross_cut/slices"
  case effectCrossCutOffset = "effect/cross_cut/offset"
  case effectCrossCutSpeedV = "effect/cross_cut/speedV"
  case effectCrossCutTime = "effect/cross_cut/time"

  case effectLiquidAmount = "effect/liquid/amount"
  case effectLiquidScale = "effect/liquid/scale"
  case effectLiquidTime = "effect/liquid/time"

  case effectOutlinerAmount = "effect/outliner/amount"
  case effectOutlinerPassthrough = "effect/outliner/passthrough"

  case effectDotPatternDots = "effect/dot_pattern/dots"
  case effectDotPatternSize = "effect/dot_pattern/size"
  case effectDotPatternBlur = "effect/dot_pattern/blur"

  case effectPosterizeLevels = "effect/posterize/levels"

  case effectTvGlitchDistortion = "effect/tv_glitch/distortion"
  case effectTvGlitchDistortion2 = "effect/tv_glitch/distortion2"
  case effectTvGlitchSpeed = "effect/tv_glitch/speed"
  case effectTvGlitchRollSpeed = "effect/tv_glitch/rollSpeed"

  case effectHalfToneAngle = "effect/half_tone/angle"
  case effectHalfToneScale = "effect/half_tone/scale"

  case effectLinocutScale = "effect/linocut/scale"

  case effectShifterAmount = "effect/shifter/amount"
  case effectShifterAngle = "effect/shifter/angle"

  case effectMirrorSide = "effect/mirror/side"

  case effectGlowSize = "effect/glow/size"
  case effectGlowAmount = "effect/glow/amount"
  case effectGlowDarkness = "effect/glow/darkness"

  case effectVignetteOffset = "effect/vignette/offset"
  case effectVignetteDarkness = "effect/vignette/darkness"

  case effectTiltShiftAmount = "effect/tilt_shift/amount"
  case effectTiltShiftPosition = "effect/tilt_shift/position"

  case effectExtrudeBlurAmount = "effect/extrude_blur/amount"

  case effectRecolorFromColor = "effect/recolor/fromColor"
  case effectRecolorColorMatch = "effect/recolor/colorMatch"
  case effectRecolorBrightnessMatch = "effect/recolor/brightnessMatch"
  case effectRecolorSmoothness = "effect/recolor/smoothness"
  case effectRecolorToColor = "effect/recolor/toColor"

  case effectGreenScreenFromColor = "effect/green_screen/fromColor"
  case effectGreenScreenColorMatch = "effect/green_screen/colorMatch"
  case effectGreenScreenSmoothness = "effect/green_screen/smoothness"
  case effectGreenScreenSpill = "effect/green_screen/spill"

  case cameraPixelRatio = "camera/pixelRatio"
  case cameraResolutionWidth = "camera/resolution/width"
  case cameraResolutionHeight = "camera/resolution/height"

  case audioFileURI = "audio/fileURI"
}

@_spi(Internal) public extension Property {
  var enabled: Property? {
    switch rawValue {
    case _ where rawValue.hasPrefix("fill/"): .key(.fillEnabled)
    case _ where rawValue.hasPrefix("stroke/"): .key(.strokeEnabled)
    default: nil
    }
  }
}
