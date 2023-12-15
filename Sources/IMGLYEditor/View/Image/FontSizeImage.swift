import SwiftUI

struct FontSizeImage: View {
  let fontSize: Float

  var sizeLetter: SizeLetter { .init(fontSize) }

  var body: some View {
    ZStack {
      Image(systemName: "circle")
        .foregroundColor(.secondary)
      sizeLetter.icon
        .font(.system(.caption, design: .rounded).weight(.heavy))
    }
  }
}
