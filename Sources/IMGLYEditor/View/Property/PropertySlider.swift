@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct PropertySlider<T: MappedType & BinaryFloatingPoint>: View where T.Stride: BinaryFloatingPoint {
  let title: LocalizedStringResource
  let bounds: ClosedRange<T>
  let property: Property
  let mapping: Mapping
  let getter: Interactor.PropertyGetter<T>
  let setter: Interactor.PropertySetter<T>
  let propertyBlock: PropertyBlock?
  let selection: Interactor.BlockID?
  let defaultValue: T?

  typealias Mapping = (_ value: Binding<T>, _ bounds: ClosedRange<T>) -> Binding<T>

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @State private var localValue: T?

  init(_ title: LocalizedStringResource, in bounds: ClosedRange<T>, property: Property,
       mapping: @escaping Mapping = { value, _ in value },
       setter: @escaping Interactor.PropertySetter<T> = Interactor.Setter.set(),
       getter: @escaping Interactor.PropertyGetter<T> = Interactor.Getter.get(),
       propertyBlock: PropertyBlock? = nil,
       selection: Interactor.BlockID? = nil,
       defaultValue: T? = nil) {
    self.title = title
    self.bounds = bounds
    self.property = property
    self.mapping = mapping
    self.setter = setter
    self.getter = getter
    self.propertyBlock = propertyBlock
    self.selection = selection
    self.defaultValue = defaultValue
  }

  var binding: Binding<T> {
    interactor.bind(
      selection ?? id,
      propertyBlock,
      property: property,
      default: defaultValue ?? bounds.lowerBound,
      getter: getter,
      setter: setter,
      completion: nil,
    )
  }

  private var sliderBinding: Binding<T> {
    Binding(
      get: {
        localValue ?? binding.wrappedValue
      },
      set: { newValue in
        localValue = newValue
        binding.wrappedValue = newValue
      },
    )
  }

  var body: some View {
    Slider(value: mapping(sliderBinding, bounds),
           in: bounds) { started in
      if !started {
        localValue = nil
        interactor.addUndoStep()
      }
    }
    .accessibilityLabel(Text(title))
    .onAppear { localValue = nil }
  }
}
