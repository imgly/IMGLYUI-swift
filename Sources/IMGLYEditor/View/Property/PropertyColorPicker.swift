@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct PropertyColorPicker: View {
  let title: LocalizedStringResource
  let supportsOpacity: Bool
  let property: Property
  let propertyBlock: PropertyBlock?
  let selection: Interactor.BlockID?
  let defaultValue: CGColor?

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @State private var showColorPicker = false
  @State private var didAppear = false

  init(_ title: LocalizedStringResource, supportsOpacity: Bool = true, property: Property,
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
      completion: nil,
    )
  }

  var body: some View {
    ColorPicker(selection: color) {
      Text(title)
    }
    // Workaround for iOS 26 SwiftUI bug (IOS-342): when two `ColorPicker`s
    // are stacked in a `List`, the second swatch loses its inner clip mask
    // and draws the selected color as a square overlapping the rainbow ring
    // until any relayout occurs. Flipping `.id` once after first appearance
    // forces a fresh layout pass that applies the clip correctly.
    .id(didAppear)
    .task { didAppear = true }
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
