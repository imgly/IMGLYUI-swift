@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct RawSlider<T: MappedType & BinaryFloatingPoint>: View where T.Stride: BinaryFloatingPoint {
  let title: LocalizedStringResource
  let bounds: ClosedRange<T>
  let mapping: Mapping
  let getter: Interactor.RawGetter<T>
  let setter: Interactor.RawSetter<T>
  let selection: Interactor.BlockID?
  let defaultValue: T?

  typealias Mapping = (_ value: Binding<T>, _ bounds: ClosedRange<T>) -> Binding<T>

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  init(_ title: LocalizedStringResource, in bounds: ClosedRange<T>,
       mapping: @escaping Mapping = { value, _ in value },
       setter: @escaping Interactor.RawSetter<T>,
       getter: @escaping Interactor.RawGetter<T>,
       selection: Interactor.BlockID? = nil,
       defaultValue: T? = nil) {
    self.title = title
    self.bounds = bounds
    self.mapping = mapping
    self.setter = setter
    self.getter = getter
    self.selection = selection
    self.defaultValue = defaultValue
  }

  var binding: Binding<T> {
    interactor.bind(
      selection ?? id,
      default: defaultValue ?? bounds.lowerBound,
      getter: getter,
      setter: setter,
      completion: nil,
    )
  }

  var body: some View {
    Slider(value: mapping(binding, bounds),
           in: bounds) { started in
      if !started {
        interactor.addUndoStep()
      }
    }
    .accessibilityLabel(Text(title))
  }
}
