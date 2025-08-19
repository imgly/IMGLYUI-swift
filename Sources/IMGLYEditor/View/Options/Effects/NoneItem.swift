import SwiftUI

struct NoneItem: View {
  @Binding var selection: AssetSelection?

  var body: some View {
    SelectableEffectItem(
      title: String(localized: .imgly.localized("ly_img_editor_asset_library_label_none")),
      selected: selection?.identifier == nil,
    ) {
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
