import SwiftUI

struct SheetDismissButton: View {
  @EnvironmentObject private var interactor: Interactor

  var body: some View {
    Button {
      interactor.sheetDismissButtonTapped()
    } label: {
      Label {
        Text(.imgly.localized("ly_img_editor_sheet_button_close"))
      } icon: {
        Image(systemName: "chevron.down.circle.fill")
      }
      .symbolRenderingMode(.hierarchical)
      .foregroundColor(.secondary)
      .font(.title2)
    }
  }
}
