import SwiftUI

struct AddLabel: View {
  var body: some View {
    Label {
      Text(.imgly.localized("ly_img_editor_asset_library_button_add"))
    } icon: {
      Image(systemName: "plus")
    }
  }
}
