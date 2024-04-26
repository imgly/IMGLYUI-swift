@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct PropertyColorPicker: View {
  let title: LocalizedStringKey
  let supportsOpacity: Bool
  let property: Property
  let propertyBlock: PropertyBlock?
  let selection: Interactor.BlockID?
  let defaultValue: CGColor?

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @State private var showColorPicker = false

  init(_ title: LocalizedStringKey, supportsOpacity: Bool = true, property: Property,
       propertyBlock: PropertyBlock? = nil,
       selection: Interactor.BlockID? = nil,
       defaultValue: CGColor? = nil) {
    self.title = title
    self.supportsOpacity = supportsOpacity
    self.property = property
    self.propertyBlock = propertyBlock
    self.selection = selection
    self.defaultValue = defaultValue
  }

  var color: Binding<CGColor> {
    interactor.bind(
      selection ?? id,
      propertyBlock,
      property: property,
      default: defaultValue ?? .imgly.black,
      completion: nil
    )
  }

  var body: some View {
    ColorPicker(title, selection: color)
      .onTapGesture {
        // Override normal tap and show custom color picker instead.
        showColorPicker = true
      }
      .imgly
      .colorPicker(title, isPresented: $showColorPicker, selection: color,
                   supportsOpacity: supportsOpacity) { started in
        if !started {
          interactor.addUndoStep()
        }
      }
  }
}
