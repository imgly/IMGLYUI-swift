import SwiftUI

struct OptionButtonStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button(configuration)
      .background(
        RoundedRectangle(cornerRadius: 11)
          .fill(Color(uiColor: .secondarySystemGroupedBackground))
      )
  }
}
