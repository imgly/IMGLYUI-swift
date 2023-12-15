import SwiftUI

struct NoneItem: View {
  @Binding var selection: AssetSelection?

  var body: some View {
    SelectableItem(title: "None", selected: selection?.identifier == nil) {
      ZStack {
        Color(.systemGray5)
        Image(systemName: "nosign")
          .font(.largeTitle)
      }
    }
    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
    .onTapGesture {
      selection = AssetSelection()
    }
  }
}

struct NoneItem_Previews: PreviewProvider {
  static var previews: some View {
    NoneItem(selection: .constant(AssetSelection()))
  }
}
