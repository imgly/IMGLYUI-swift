@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct PropertyPicker<T: MappedEnum & Labelable>: View {
  let title: LocalizedStringResource
  let property: Property
  let cases: [T]
  let setter: Interactor.PropertySetter<T>

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  init(_ title: LocalizedStringResource, property: Property,
       cases: [T] = T.allCases.map(\.self),
       setter: @escaping Interactor.PropertySetter<T> = Interactor.Setter.set()) {
    self.title = title
    self.property = property
    self.cases = cases
    self.setter = setter
  }

  var body: some View {
    let _: [T] = interactor.enumValues(property: property)
    let selection: Binding<T?> = interactor.bind(id, property: property, setter: setter)

    MenuPicker(title: title, data: cases, selection: selection)
  }
}
