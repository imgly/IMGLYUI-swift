@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct FillColorOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @Binding var fillType: ColorFillType?

  var body: some View {
    if interactor.supportsFill(id) {
      MenuPicker<ColorFillType.AllCases>(title: "Type", data: ColorFillType.allCases, selection: $fillType)
        .disabled(interactor.sheet.type == .text)
        .accessibilityLabel("Fill Type")

      if interactor.isGradientFill(id), fillType == .gradient {
        GradientOptions()
      } else if interactor.isSolidFill(id) {
        let colorBinding = interactor.bind(
          id,
          property: .key(.fillSolidColor),
          default: .imgly.black,
          getter: temporaryColorGetter,
          setter: colorSetter,
          completion: Interactor.Completion.set(property: .key(.fillEnabled), value: true)
        )
        ColorOptions(title: "Fill Color",
                     isEnabled: interactor.bind(id, property: .key(.fillEnabled), default: false),
                     color: colorBinding,
                     addUndoStep: interactor.addUndoStep)
          .accessibilityElement(children: .contain)
          .accessibilityLabel("Fill Color")
      }
    }
  }

  /// - Note: This is a workaround for an engine issue where the state is not consistent
  ///         when switching between solid and gradient color fill mode.
  let temporaryColorGetter: Interactor.PropertyGetter<CGColor> = { engine, id, _, property in
    do {
      let blockType = try engine.block.getType(id)
      if blockType == Interactor.BlockType.text.rawValue,
         let textColor = try engine.block.getTextColors(id).first?.cgColor {
        return textColor
      }
      return try engine.block.get(id, property: property)
    } catch {
      return .imgly.black
    }
  }

  let colorSetter: Interactor.PropertySetter<CGColor> = { engine, blocks, _, property, value, completion in
    var didChange = false

    try blocks.forEach {
      guard let color = Interactor.Color(cgColor: value) else { return }
      let blockType = try engine.block.getType($0)

      if blockType == Interactor.BlockType.text.rawValue {
        if let originalTextColor = try engine.block.getTextColors($0).first, originalTextColor != color {
          didChange = true
          try engine.block.setTextColor($0, color: color)
        }
      } else {
        let originalColor: Interactor.Color = try engine.block.get($0, property: property)
        if originalColor != color {
          didChange = true
          try engine.block.set($0, property: property, value: value)
        }
      }
    }
    return try (completion?(engine, blocks, didChange) ?? false) || didChange
  }
}

struct GradientOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    if interactor.isGradientFill(id) {
      ColorOptions(title: "Gradient Start Color",
                   color: gradientBinding(.start, defaultValue: .imgly.black),
                   addUndoStep: interactor.addUndoStep)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gradient Start Color")
      MeasurementScalePicker(value: gradientAngleBinding(), unit: UnitAngle.degrees, in: -180 ... 180,
                             tickStep: 3, tickSpacing: 10) { started in
        if !started {
          interactor.addUndoStep()
        }
      }
      .accessibilityLabel("Gradient Angle")
      ColorOptions(title: "Gradient End Color",
                   color: gradientBinding(.end, defaultValue: .imgly.black),
                   addUndoStep: interactor.addUndoStep)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gradient End Color")
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
    let getter: Interactor.PropertyGetter<CGColor> = { engine, id, _, _ in
      do {
        let colorStops: [GradientColorStop] = try engine.block
          .get(id, .fill, property: .key(.fillGradientColors))
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
          .get($0, .fill, property: .key(.fillGradientColors))

        let original = colorStops[position.rawValue]
        if original.color != color {
          didChange = true
          let modified = GradientColorStop(color: color, stop: original.stop)
          colorStops[position.rawValue] = modified

          try engine.block.set($0, .fill, property: .key(.fillGradientColors), value: colorStops)
        }
      }

      return try (completion?(engine, blocks, didChange) ?? false) || didChange
    }

    return interactor.bind(
      id,
      .fill,
      property: .key(.fillGradientColors),
      default: defaultValue,
      getter: getter,
      setter: setter
    )
  }

  private func gradientAngleBinding() -> Binding<Double> {
    let properties: [Property] = [
      .key(.fillGradientLinearStartX),
      .key(.fillGradientLinearStartY),
      .key(.fillGradientLinearEndX),
      .key(.fillGradientLinearEndY),
    ]

    let gradientAngleGetter: Interactor.PropertyGetter<Double> = { engine, id, _, _ in
      let points: [Float] = try properties.map { try engine.block.get(id, .fill, property: $0) }
      let pointsCG = points.map { Double($0) }
      let start = CGPoint(x: pointsCG[0], y: pointsCG[1])
      let end = CGPoint(x: pointsCG[2], y: pointsCG[3])
      return self.controlPointsToAngle(points: (start, end))
    }

    let gradientAngleSetter: Interactor.PropertySetter<Double> = { engine, blocks, _, _, value, completion in
      let (start, end) = self.angleToControlPoints(angle: CGFloat(value))
      let points = [start.x, start.y, end.x, end.y]

      let changed = try blocks.filter { id in
        let hasChanged = try points.enumerated().contains { index, value in
          let currentValue: Float = try engine.block.get(id, .fill, property: properties[index])
          return currentValue != Float(value)
        }
        return hasChanged
      }

      try changed.forEach { id in
        try points.enumerated().forEach { index, value in
          try engine.block.set(id, .fill, property: properties[index], value: Float(value))
        }
      }

      let didChange = !changed.isEmpty
      return try (completion?(engine, blocks, didChange) ?? false) || didChange
    }

    let gradientAngleBinding: Binding<Double> = interactor.bind(
      id,
      property: .key(.fillGradientColors),
      default: 0,
      getter: gradientAngleGetter,
      setter: gradientAngleSetter
    )
    return gradientAngleBinding
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
    let angle = (atan2(y, x) * 180) / Double.pi
    return angle
  }
}
