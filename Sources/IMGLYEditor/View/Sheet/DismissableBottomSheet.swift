import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
@_spi(Internal) import IMGLYCoreUI

struct DismissableBottomSheet<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    BottomSheet {
      content
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            SheetDismissButton()
              .buttonStyle(.borderless)
          }
        }
    }
  }
}

struct DismissableBottomSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.add, .image))
  }
}
