import SwiftUI

struct ResizePicker<Data, Item: View>: View where Data: RandomAccessCollection, Data.Element: Hashable {
  let title: String
  let data: Data
  @Binding var selection: Data.Element
  @ViewBuilder var itemBuilder: (Data.Element) -> Item
  var label: (Data.Element?) -> String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .padding(.leading, 8)
      Menu {
        Picker(selection: $selection) {
          ForEach(data, id: \.self) { value in
            itemBuilder(value)
          }
        } label: {
          EmptyView()
        }
        .pickerStyle(.inline)
        .labelStyle(.titleAndIcon)
      } label: {
        HStack {
          Text(label(selection))
            .foregroundColor(.primary)
          Spacer()
          Image(systemName: "chevron.up.chevron.down")
            .foregroundColor(.primary)
            .padding(.leading, 12)
        }
        .frame(height: 34)
        .padding(.horizontal, 10)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
      }
      .accessibilityLabel(title)
    }
  }
}
