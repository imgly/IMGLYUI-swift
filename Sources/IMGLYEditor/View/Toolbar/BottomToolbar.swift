@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct BottomToolbar<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    content
      .background {
        GeometryReader { geo in
          Color.clear
            .preference(key: BottomBarContentGeometryKey.self, value: Geometry(geo, Canvas.safeCoordinateSpace))
        }
      }
      .ignoresSafeArea(.keyboard)
  }
}

struct BottomToolbar_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.libraryAdd {
      AssetLibrarySheet(content: .image)
    }, .image))
  }
}
