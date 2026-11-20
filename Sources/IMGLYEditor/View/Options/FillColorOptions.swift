@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct FillColorOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @Binding var fillType: ColorFillType?

  var body: some View {
    if interactor.supportsFill(id) {
      MenuPicker<[ColorFillType]>(
        title: .imgly.localized("ly_img_editor_sheet_fill_stroke_label_type"),
        data: ColorFillType.offered,
        selection: $fillType,
      )
      // Text and captions support only a solid fill — no gradient (captions also sync only the solid color).
      .disabled(interactor.sheet.content == .text || interactor.sheet.content == .caption)
      .accessibilityLabel("Fill Type")

      if interactor.isGradientFill(id), fillType?.isGradient == true {
        GradientOptions()
      } else if interactor.isSolidFill(id) {
        let colorsBinding = interactor.bind(
          id,
          property: .key(.fillSolidColor),
          default: [CGColor.imgly.black],
          getter: colorsGetter,
          setter: colorsSetter,
          completion: Interactor.Completion.set(property: .key(.fillEnabled), value: true),
        )
        ColorOptions(title: .imgly.localized("ly_img_editor_sheet_fill_stroke_color_picker_title_fill"),
                     isEnabled: interactor.bind(id, property: .key(.fillEnabled), default: false),
                     colors: colorsBinding,
                     addUndoStep: interactor.addUndoStep)
          .accessibilityElement(children: .contain)
          .accessibilityLabel(Text(.imgly.localized("ly_img_editor_sheet_fill_stroke_color_picker_title_fill")))
      }
    }
  }

  /// The distinct colours across the effective text range (or the solid fill colour for non-text
  /// blocks). A single colour marks the matching preset as selected; several mark none.
  /// - Note: Reading the text colours instead of the fill property is also a workaround for an
  ///         engine issue where the state is not consistent when switching between solid and
  ///         gradient color fill mode.
  let colorsGetter: Interactor.PropertyGetter<[CGColor]> = { engine, id, _, property in
    do {
      // A caption's visible colour is a run colour (like text), not `fill/solid/color`, so read it via the
      // text-colour API. Captions use the whole-block range: the engine only registers the caption-track
      // colour sync for a whole-block `setTextColor` (from<0 && to<0). Text uses its selected range.
      let type = try engine.block.getType(id)
      let isCaption = type == Interactor.BlockType.caption.rawValue
      if type == Interactor.BlockType.text.rawValue || isCaption {
        let range = isCaption ? nil : try engine.block.effectiveTextRange(id)
        var distinct: [Interactor.Color] = []
        for color in try engine.block.getTextColors(id, in: range) where !distinct.contains(color) {
          distinct.append(color)
        }
        let cgColors = distinct.compactMap(\.cgColor)
        if !cgColors.isEmpty {
          return cgColors
        }
      }
      return [try engine.block.get(id, property: property)]
    } catch {
      return [.imgly.black]
    }
  }

  /// Applies the first colour uniformly — to the effective text range for text blocks, or to the
  /// fill property otherwise.
  let colorsSetter: Interactor.PropertySetter<[CGColor]> = { engine, blocks, _, property, value, completion in
    var didChange = false

    if let newColor = value.first, let color = Interactor.Color(cgColor: newColor) {
      try blocks.forEach {
        let blockType = try engine.block.getType($0)

        let isCaption = blockType == Interactor.BlockType.caption.rawValue
        if blockType == Interactor.BlockType.text.rawValue || isCaption {
          // Whole-block range for captions: the engine only registers the caption-track colour sync for a
          // whole-block `setTextColor` (from<0 && to<0). Text uses its selected range.
          let range = isCaption ? nil : try engine.block.effectiveTextRange($0)
          let originalColors = try engine.block.getTextColors($0, in: range)
          let isUnchanged = !originalColors.isEmpty && originalColors.allSatisfy { $0 == color }
          if !isUnchanged {
            didChange = true
            try engine.block.setTextColor($0, color: color, in: range)
          }
        } else {
          let originalColor: Interactor.Color = try engine.block.get($0, property: property)
          if originalColor != color {
            didChange = true
            try engine.block.set($0, property: property, value: newColor)
          }
        }
      }
    }
    return try (completion?(engine, blocks, didChange) ?? false) || didChange
  }
}

/// The colors of a gradient, and the angle of a linear one: the fill of the selected block, or with `.strokeFill` the
/// fill that paints its stroke.
struct GradientOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var propertyBlock: PropertyBlock = .fill

  /// The stroke's labels differ from the fill's, so a sheet that shows both gradients names each control once.
  private var labelPrefix: String {
    propertyBlock == .strokeFill ? "Stroke " : ""
  }

  private var style: ColorPropertyButtonStyle {
    propertyBlock == .strokeFill ? .stroke : .fill
  }

  var body: some View {
    if interactor.isGradientFill(id, propertyBlock) {
      ColorOptions(title: .imgly.localized("ly_img_editor_sheet_gradient_color_picker_title_start"),
                   color: gradientBinding(.start, defaultValue: .imgly.black),
                   addUndoStep: interactor.addUndoStep,
                   style: style)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(labelPrefix)Gradient Start Color")
      // A radial or conical gradient has no angle.
      if interactor.isLinearGradientFill(id, propertyBlock) {
        MeasurementScalePicker(value: gradientAngleBinding(), unit: UnitAngle.degrees, in: -180 ... 180,
                               tickStep: 3, tickSpacing: 10) { started in
          if !started {
            interactor.addUndoStep()
          }
        }
        .accessibilityLabel("\(labelPrefix)Gradient Angle")
      }
      ColorOptions(title: .imgly.localized("ly_img_editor_sheet_gradient_color_picker_title_end"),
                   color: gradientBinding(.end, defaultValue: .imgly.black),
                   addUndoStep: interactor.addUndoStep,
                   style: style)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(labelPrefix)Gradient End Color")
    }
  }
}

// MARK: - Helpers

extension GradientOptions {
  private enum GradientPosition: Int {
    case start = 0
    case end = 1
  }

  typealias GradientColorStop = Interactor.GradientColorStop

  private func gradientBinding(_ position: GradientPosition, defaultValue: CGColor) -> Binding<CGColor> {
    let propertyBlock = propertyBlock
    let getter: Interactor.PropertyGetter<CGColor> = { engine, id, _, _ in
      do {
        let colorStops: [GradientColorStop] = try engine.block
          .get(id, propertyBlock, property: .key(.fillGradientColors))
        // A gradient from the API can have one stop, so the end stop can be missing.
        guard colorStops.indices.contains(position.rawValue) else { return defaultValue }
        return colorStops[position.rawValue].color.cgColor ?? defaultValue
      } catch {
        return defaultValue
      }
    }

    let setter: Interactor.PropertySetter<CGColor> = { engine, blocks, _, _, value, completion in
      var didChange = false

      try blocks.forEach {
        guard let color = Interactor.Color(cgColor: value) else { return }
        var colorStops: [GradientColorStop] = try engine.block
          .get($0, propertyBlock, property: .key(.fillGradientColors))
        guard colorStops.indices.contains(position.rawValue) else { return }

        let original = colorStops[position.rawValue]
        if original.color != color {
          didChange = true
          let modified = GradientColorStop(color: color, stop: original.stop)
          colorStops[position.rawValue] = modified

          try engine.block.set($0, propertyBlock, property: .key(.fillGradientColors), value: colorStops)
        }
      }

      return try (completion?(engine, blocks, didChange) ?? false) || didChange
    }

    return interactor.bind(
      id,
      propertyBlock,
      property: .key(.fillGradientColors),
      default: defaultValue,
      getter: getter,
      setter: setter,
    )
  }

  private func gradientAngleBinding() -> Binding<Double> {
    let propertyBlock = propertyBlock
    let properties: [Property] = [
      .key(.fillGradientLinearStartX),
      .key(.fillGradientLinearStartY),
      .key(.fillGradientLinearEndX),
      .key(.fillGradientLinearEndY),
    ]

    let gradientAngleGetter: Interactor.PropertyGetter<Double> = { engine, id, _, _ in
      // A switch to Solid replaces the fill or destroys the stroke fill, so a re-read finds no linear gradient.
      guard let points: [Float] = try? properties.map({ try engine.block.get(id, propertyBlock, property: $0) }) else {
        return 0
      }
      let pointsCG = points.map { Double($0) }
      let start = CGPoint(x: pointsCG[0], y: pointsCG[1])
      let end = CGPoint(x: pointsCG[2], y: pointsCG[3])
      return self.controlPointsToAngle(points: (start, end))
    }

    let gradientAngleSetter: Interactor.PropertySetter<Double> = { engine, blocks, _, _, value, completion in
      let (start, end) = self.angleToControlPoints(angle: CGFloat(value))
      let points = [start.x, start.y, end.x, end.y]

      let changed = try blocks.filter { id in
        try points.enumerated().contains { index, value in
          let currentValue: Float = try engine.block.get(id, propertyBlock, property: properties[index])
          return currentValue != Float(value)
        }
      }

      try changed.forEach { id in
        try points.enumerated().forEach { index, value in
          try engine.block.set(id, propertyBlock, property: properties[index], value: Float(value))
        }
      }

      let didChange = !changed.isEmpty
      return try (completion?(engine, blocks, didChange) ?? false) || didChange
    }

    return interactor.bind(
      id,
      property: .key(.fillGradientColors),
      default: 0,
      getter: gradientAngleGetter,
      setter: gradientAngleSetter,
    )
  }

  private func angleToControlPoints(angle: Double) -> (CGPoint, CGPoint) {
    let absRotationInDegrees = ((angle.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360))
    let slope = tan(absRotationInDegrees * .pi / 180)

    var startX: Double
    var startY: Double
    var endX: Double
    var endY: Double

    switch absRotationInDegrees {
    case 0 ... 45, 315 ... 360:
      startX = 0
      startY = 0.5 - 0.5 * slope
      endX = 1
      endY = 0.5 + 0.5 * slope
    case 135 ... 225:
      startX = 1
      startY = 0.5 + 0.5 * slope
      endX = 0
      endY = 0.5 - 0.5 * slope
    case 45 ... 135:
      startX = 0.5 - 0.5 / slope
      startY = 0.0
      endX = 0.5 + 0.5 / slope
      endY = 1.0
    default:
      startX = 0.5 + 0.5 / slope
      startY = 1.0
      endX = 0.5 - 0.5 / slope
      endY = 0.0
    }

    let start = CGPoint(x: startX, y: startY)
    let end = CGPoint(x: endX, y: endY)
    return (start, end)
  }

  private func controlPointsToAngle(points: (CGPoint, CGPoint)) -> Double {
    let x = points.1.x - points.0.x
    let y = points.1.y - points.0.y
    return (atan2(y, x) * 180) / Double.pi
  }
}
