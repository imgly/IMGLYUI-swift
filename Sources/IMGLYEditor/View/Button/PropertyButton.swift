import SwiftUI
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import enum IMGLYCoreUI.HorizontalAlignment

struct PropertyButton<T: Labelable>: View {
  let property: T
  @Binding var selection: T?

  var body: some View {
    GenericPropertyButton(property: property, selection: $selection) {
      property.label
    }
  }
}

struct GenericPropertyButton<T: Equatable, Label: View>: View {
  let property: T
  @Binding var selection: T?
  @ViewBuilder let label: () -> Label

  private var isSelected: Bool { selection == property }
  private var isDisabled: Bool { selection == nil }

  var body: some View {
    Button {
      selection = isSelected ? nil : property
    } label: {
      label()
    }
    .foregroundColor(isSelected || isDisabled ? .accentColor : .primary)
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
