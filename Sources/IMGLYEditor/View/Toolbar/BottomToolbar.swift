@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct BottomToolbar<Content: View>: View {
  let title: Text
  @ViewBuilder let content: Content

  var body: some View {
    NavigationView {
      content
        .background {
          GeometryReader { geo in
            Color.clear
              .preference(key: BottomBarContentGeometryKey.self, value: Geometry(geo, Canvas.safeCoordinateSpace))
          }
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            BottomBarCloseButton()
              .buttonStyle(.borderless)
          }
        }
    }
    .navigationViewStyle(.stack)
  }
}

struct BottomToolbar_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.add, .image))
  }
}
