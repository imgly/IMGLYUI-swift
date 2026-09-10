@_spi(Internal) import IMGLYCore
import SwiftUI

@_spi(Internal) public struct MeasurementScalePicker<V, UnitType>: View where V: BinaryFloatingPoint,
  V.Stride: BinaryFloatingPoint,
  UnitType: Dimension {
  @_spi(Internal) public init(value: Binding<V>,
                              unit: UnitType,
                              in bounds: ClosedRange<V>,
                              neutralValue: V? = 0,
                              tickStep: V.Stride = 1,
                              tickSpacing: CGFloat = 8,
                              onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
    _value = value
    self.unit = unit
    self.bounds = bounds
    self.neutralValue = neutralValue
    self.tickStep = tickStep
    self.tickSpacing = tickSpacing
    self.onEditingChanged = onEditingChanged
  }

  @Binding var value: V
  let unit: UnitType
  let bounds: ClosedRange<V>
  let neutralValue: V?
  let tickStep: V.Stride
  let tickSpacing: CGFloat
  let onEditingChanged: (Bool) -> Void

  func format(_ value: V) -> String {
    let value = Measurement(value: Double(value), unit: unit)
    let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
    return value.formatted(.measurement(width: .narrow, numberFormatStyle: format))
  }

  func formatNonNegativeZero(_ value: V) -> String {
    let formattedString = format(value)
    let negativeZeroString = format(-0.0)
    if formattedString == negativeZeroString {
      return format(0.0)
    }
    return formattedString
  }

  var cursorColor: AnyShapeStyle {
    guard let neutralValue else {
      return AnyShapeStyle(.primary)
    }
    let neutral = V(neutralValue)
    if formatNonNegativeZero(value) == formatNonNegativeZero(neutral) {
      return AnyShapeStyle(.primary)
    } else {
      return AnyShapeStyle(.tint)
    }
  }

  @ViewBuilder var cursor: some View {
    Text(formatNonNegativeZero(value))
      .padding(4)
      .font(.headline)
      .foregroundStyle(cursorColor)
  }

  @_spi(Internal) public var body: some View {
    ScalePicker(value: $value, in: bounds, neutralValue: neutralValue,
                tickStep: tickStep, tickSpacing: tickSpacing, onEditingChanged: onEditingChanged)
      .imgly.inverseMask(alignment: .center) {
        cursor
          .background()
      }
      .overlay {
        cursor
          .allowsHitTesting(false)
      }
      .mask {
        GeometryReader { geo in
          let colors: [Color] = [.black.opacity(0.1), .black.opacity(1.0)]
          HStack(spacing: 0) {
            Rectangle()
              .fill(.linearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
            Rectangle()
              .frame(width: geo.size.width * 2 / 3)
            Rectangle()
              .fill(.linearGradient(colors: colors, startPoint: .trailing, endPoint: .leading))
          }
          .environment(\.layoutDirection, .leftToRight)
        }
      }
      .accessibilityElement()
      .accessibilityValue(format(value))
      .accessibilityAdjustableAction { direction in
        let bounds = ClosedRange(uncheckedBounds: (lower: V(bounds.lowerBound), upper: V(bounds.upperBound)))
        switch direction {
        case .increment:
          value = (value + 1).clamped(to: bounds)
        case .decrement:
          value = (value - 1).clamped(to: bounds)
        @unknown default:
          break
        }
      }
  }
}
