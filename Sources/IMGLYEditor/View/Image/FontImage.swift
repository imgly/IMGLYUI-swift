@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct FontImage: View {
  let font: SwiftUI.Font

  var body: some View {
    Text("Ag")
      .font(font)
  }
}

struct FontImage_Previews: PreviewProvider {
  static let size: CGFloat = 28

  @ViewBuilder static var fonts: some View {
    VStack {
      FontImage(font: .custom("HelveticaNeue-Bold", size: size))
      FontImage(font: .custom("Arial-ItalicMT", size: size))
      FontImage(font: .custom("Menlo", size: size))
      FontImage(font: .custom("Verdana", size: size))
      FontImage(font: .custom("MarkerFelt-Wide", size: size))
      FontImage(font: .custom("AmericanTypewriter", size: size))
      FontImage(font: .custom("Baskerville", size: size))
      FontImage(font: .custom("Chalkduster", size: size))
    }
    .font(.title)
  }

  static var previews: some View {
    fonts
    fonts.imgly.nonDefaultPreviewSettings()
  }
}
