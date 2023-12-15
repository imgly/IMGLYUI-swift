import SwiftUI

struct BottomBarButtonStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button(configuration)
      .tint(.primary)
  }
}
