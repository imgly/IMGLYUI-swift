import SwiftUI
@_spi(Internal) import IMGLYCoreUI

/// Custom view that looks like `.pickerStyle(.menu)` but allows to use a custom label for the selection next to the
/// up&down chevron.
struct MenuPicker<Data>: View
  where Data: RandomAccessCollection, Data.Element: Labelable {
  let title: LocalizedStringKey
  let data: Data
  @Binding var selection: Data.Element?

  var body: some View {
    HStack {
      Text(title)
      Spacer()
      HStack { // Second HStack + Spacer make sure to have the Menu appear at the same x position.
        Spacer()
        Menu {
          Picker(selection: $selection) {
            ForEach(data, id: \.self) { value in
              value.label
                .tag(value as Data.Element?)
            }
          } label: {
            EmptyView()
          }
          .pickerStyle(.inline)
          .labelStyle(.titleAndIcon) // Make sure to show labels for iOS 15
        } label: {
          HStack(spacing: 4) {
            if let selection {
              Text(selection.localizedStringKey)
            }
            Image(systemName: "chevron.up.chevron.down")
              .font(.footnote.weight(.medium))
          }
          .frame(maxWidth: .infinity, alignment: .trailing)
          .lineLimit(1)
        }
      }
    }
    .accessibilityElement(children: .combine)
  }
}
