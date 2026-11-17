import SwiftUI
@_spi(Internal) import IMGLYCoreUI

/// A label with a ``NumberStepperField``, for the `Float` speed and the `Double` duration.
struct ClipSpeedRow<T: BinaryFloatingPoint>: View {
  let title: LocalizedStringResource
  @Binding var value: T
  let bounds: ClosedRange<T>
  let step: T
  let unit: String
  let decimals: Int
  let isEnabled: Bool
  var showsButtons: Bool = true
  /// Forwarded to ``NumberStepperField``.
  var onEditingChanged: ((Bool) -> Void)?

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    // At accessibility sizes the label goes above the control.
    Group {
      if dynamicTypeSize.isAccessibilitySize {
        VStack(alignment: .leading, spacing: 8) {
          label
          field
        }
        .padding(.vertical, 8)
      } else {
        HStack(spacing: 12) {
          label
          Spacer(minLength: 0)
          field
        }
      }
    }
    // The field grows with Dynamic Type, so a fixed height would clip it.
    .frame(minHeight: ClipSpeedDefaults.rowHeight)
    .padding(.horizontal, 16)
  }

  private var label: some View {
    Text(title)
      .foregroundStyle(.primary)
      .font(.body)
      .lineLimit(1)
      .layoutPriority(1)
  }

  private var field: some View {
    NumberStepperField(
      value: $value,
      title: title,
      bounds: bounds,
      step: step,
      unit: unit,
      decimals: decimals,
      isEnabled: isEnabled,
      showsButtons: showsButtons,
      onEditingChanged: onEditingChanged,
    )
    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
  }
}
