import SwiftUI

struct ClipSpeedRow: View {
  let title: LocalizedStringResource
  @Binding var value: String
  let placeholder: String
  let suffix: String
  let isEnabled: Bool
  let inputWidth: CGFloat
  let focusedField: FocusState<ClipSpeedField?>.Binding
  let field: ClipSpeedField
  var previousSpeed: Float?
  var nextSpeed: Float?
  var previousSpeedProvider: (() -> Float?)?
  var nextSpeedProvider: (() -> Float?)?
  var onSpeedSelected: ((Float) -> Void)?

  var body: some View {
    HStack(spacing: 12) {
      Text(title)
        .foregroundStyle(.primary)
        .font(.body)
        .lineLimit(1)
        .layoutPriority(1)
      Spacer(minLength: 0)
      HStack(spacing: 6) {
        ClipSpeedInputPill(
          value: $value,
          placeholder: placeholder,
          suffix: suffix,
          isEnabled: isEnabled,
          inputWidth: inputWidth,
          focusedField: focusedField,
          field: field,
        )
        if let onSpeedSelected {
          ClipSpeedStepper(
            isEnabled: isEnabled,
            previousSpeed: previousSpeed,
            nextSpeed: nextSpeed,
            previousSpeedProvider: previousSpeedProvider ?? { previousSpeed },
            nextSpeedProvider: nextSpeedProvider ?? { nextSpeed },
            onSpeedSelected: onSpeedSelected,
          )
        }
      }
    }
    .frame(height: ClipSpeedDefaults.rowHeight)
    .padding(.horizontal, 16)
  }
}
