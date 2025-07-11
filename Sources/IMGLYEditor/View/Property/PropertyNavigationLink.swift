@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct PropertyNavigationLink<T: MappedEnum & Labelable>: View {
  let title: LocalizedStringResource
  let property: Property

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  init(_ title: LocalizedStringResource, property: Property) {
    self.title = title
    self.property = property
  }

  var body: some View {
    let values: [T] = interactor.enumValues(property: property)
    let binding: Binding<T?> = interactor.bind(id, property: property)
    let selection: Binding<T.ID?> = .init {
      binding.wrappedValue?.id
    } set: { id in
      let value = values.first { id == $0.id }
      if let value {
        binding.wrappedValue = value
      }
    }

    NavigationLinkPicker(title: title, data: [values], selection: selection) { value, isSelected in
      Label {
        Text(value.localizedStringResource)
      } icon: {
        Image(systemName: "checkmark")
      }
      .labelStyle(.icon(hidden: !isSelected))
    } linkLabel: { selection in
      if let selection {
        Text(selection.localizedStringResource)
      }
    }
  }
}
