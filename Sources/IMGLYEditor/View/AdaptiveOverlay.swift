import SwiftUI

struct AdaptiveOverlay<Content: View, Overlay: View>: View {
  @ViewBuilder let content: Content
  @ViewBuilder let overlay: Overlay

  @State var padding: CGFloat?

  var body: some View {
    ZStack {
      content
        .background {
          GeometryReader { geo in
            Color.clear
              .preference(key: ContentSizeKey.self, value: geo.size)
          }
        }
        .onPreferenceChange(ContentSizeKey.self) { newValue in
          padding = (newValue?.width ?? 0) / 2
        }
        .padding([.trailing], padding)
      overlay
        .padding([.leading], padding)
    }
  }
}

private struct ContentSizeKey: PreferenceKey {
  static let defaultValue: CGSize? = nil
  static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
    value = value ?? nextValue()
  }
}
