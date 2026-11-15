@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

/// Stepper bound to an engine property. Its initialiser matches
/// ``PropertySlider``'s, plus a required `step:`.
struct PropertyStepper<T: MappedType & BinaryFloatingPoint>: View {
  let title: LocalizedStringResource
  let bounds: ClosedRange<T>
  let step: T
  let property: Property
  let unit: String?
  let decimals: Int?
  let getter: Interactor.PropertyGetter<T>
  let setter: Interactor.PropertySetter<T>
  let propertyBlock: PropertyBlock?
  let selection: Interactor.BlockID?
  let defaultValue: T?

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  init(_ title: LocalizedStringResource, in bounds: ClosedRange<T>, step: T,
       property: Property,
       unit: String? = nil,
       decimals: Int? = nil,
       setter: @escaping Interactor.PropertySetter<T> = Interactor.Setter.set(),
       getter: @escaping Interactor.PropertyGetter<T> = Interactor.Getter.get(),
       propertyBlock: PropertyBlock? = nil,
       selection: Interactor.BlockID? = nil,
       defaultValue: T? = nil) {
    self.title = title
    self.bounds = bounds
    self.step = step
    self.property = property
    self.unit = unit
    self.decimals = decimals
    self.setter = setter
    self.getter = getter
    self.propertyBlock = propertyBlock
    self.selection = selection
    self.defaultValue = defaultValue
  }

  private var binding: Binding<T> {
    interactor.bind(
      selection ?? id, propertyBlock, property: property,
      default: defaultValue ?? bounds.lowerBound,
      getter: getter, setter: setter, completion: nil,
    )
  }

  var body: some View {
    // At accessibility sizes the scaled control fills the row, so the label
    // goes above it.
    if dynamicTypeSize.isAccessibilitySize {
      VStack(alignment: .leading, spacing: 8) {
        label
        field
      }
    } else {
      HStack(spacing: 12) {
        label
        Spacer(minLength: 0)
        field
      }
    }
  }

  private var label: some View {
    Text(title)
      .lineLimit(2)
      .minimumScaleFactor(0.85)
  }

  private var field: some View {
    NumberStepperField(
      value: binding, title: title, bounds: bounds,
      step: step, unit: unit, decimals: decimals,
    ) { isEditing in
      // Called once per press, hold, typed edit, or VoiceOver adjustment, so
      // a hold adds one undo step.
      if !isEditing {
        interactor.addUndoStep()
      }
    }
    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
  }
}
