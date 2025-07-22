@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct FontSizeSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var fontSizeLetter: Binding<SizeLetter?> {
    let fontSize: Binding<Float?> = interactor.bind(id, property: .key(.textFontSize))
    return .init {
      guard let fontSize = fontSize.wrappedValue else {
        return nil
      }
      return SizeLetter(fontSize)
    } set: { sizeLetter in
      fontSize.wrappedValue = sizeLetter?.fontSize
    }
  }

  @ViewBuilder func propertyButton(property: SizeLetter) -> some View {
    GenericPropertyButton(property: property, selection: fontSizeLetter) {
      Label {
        Text(property.localizedStringResource)
      } icon: {
        property.icon
          .font(.system(.headline, design: .rounded))
      }
    }
  }

  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_postcard_sheet_size_title")) {
      List {
        PropertyStack(.imgly.localized("ly_img_editor_postcard_sheet_size_label_message")) {
          propertyButton(property: .small)
          propertyButton(property: .medium)
          propertyButton(property: .large)
        }
      }
    }
  }
}
