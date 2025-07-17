@_spi(Internal) import IMGLYCore
@_spi(Internal) import enum IMGLYCoreUI.StrokeStyle
import SwiftUI

struct StrokeOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @Binding var isEnabled: Bool

  var body: some View {
    if interactor.supportsStroke(id) {
      StrokeColorOptions()
      if isEnabled {
        PropertySlider<Float>("Width", in: -3 ... 3, property: .key(.strokeWidth)) { value, bounds in
          .init {
            value.wrappedValue > 0 ? log(value.wrappedValue) : bounds.lowerBound
          } set: { newValue in
            value.wrappedValue = exp(newValue)
          }
        }
        PropertyPicker<StrokeStyle>("Style", property: .key(.strokeStyle))
        PropertyPicker<StrokePosition>("Position", property: .key(.strokePosition))
          .disabled(interactor.sheet.content == .text)
        PropertyPicker<StrokeJoin>("Join", property: .key(.strokeCornerGeometry))
      }
    }
  }
}

struct StrokeOptions_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.fillStroke(), .shape))
  }
}
