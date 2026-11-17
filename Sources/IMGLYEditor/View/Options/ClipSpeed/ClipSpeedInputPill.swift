import SwiftUI

struct ClipSpeedInputPill: View {
  @Binding var value: String
  let placeholder: String
  let suffix: String
  let isEnabled: Bool
  let inputWidth: CGFloat
  let focusedField: FocusState<ClipSpeedField?>.Binding
  let field: ClipSpeedField

  private var textColor: Color {
    isEnabled ? .accentColor : Color(.secondaryLabel)
  }

  var body: some View {
    HStack(spacing: 2) {
      TextField(
        "",
        text: $value,
        prompt: Text(placeholder).foregroundColor(Color(.secondaryLabel)),
      )
      .keyboardType(.decimalPad)
      .submitLabel(.done)
      .onSubmit { focusedField.wrappedValue = nil }
      .multilineTextAlignment(.trailing)
      .foregroundStyle(textColor)
      .focused(focusedField, equals: field)
      Text(verbatim: suffix)
        .foregroundStyle(textColor)
    }
    .font(.body)
    .padding(.horizontal, 14)
    .frame(
      minWidth: inputWidth,
      maxWidth: inputWidth,
      minHeight: ClipSpeedDefaults.inputHeight,
      maxHeight: ClipSpeedDefaults.inputHeight,
    )
    .background(Color(.tertiarySystemFill))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .disabled(!isEnabled)
  }
}
