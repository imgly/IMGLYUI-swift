import SwiftUI
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import enum IMGLYCoreUI.HorizontalAlignment

struct PropertyButton<T: Labelable>: View {
  let property: T
  @Binding var selection: T?
  /// When `false`, tapping the already-selected button re-applies its value instead of clearing the
  /// selection. Use for mutually-exclusive rows (e.g. letter case) where there is no "off" state.
  var allowsDeselection = true

  var body: some View {
    GenericPropertyButton(property: property, selection: $selection, allowsDeselection: allowsDeselection) {
      property.label
    }
  }
}

struct GenericPropertyButton<T: Equatable, Label: View>: View {
  let property: T
  @Binding var selection: T?
  var allowsDeselection = true
  @ViewBuilder let label: () -> Label

  private var isSelected: Bool { selection == property }
  private var isDisabled: Bool { selection == nil }

  private var foregroundColor: Color {
    if isDisabled { return .secondary }
    return isSelected ? .accentColor : .primary
  }

  var body: some View {
    Button {
      selection = (allowsDeselection && isSelected) ? nil : property
    } label: {
      label()
    }
    .foregroundColor(foregroundColor)
    .disabled(isDisabled)
  }
}

struct TextPropertyButton_Previews: PreviewProvider {
  @State static var property: HorizontalAlignment? = .center

  static var previews: some View {
    HStack {
      ForEach(HorizontalAlignment.allCases) {
        PropertyButton(property: $0, selection: $property)
      }
    }
    .labelStyle(.iconOnly)
  }
}
