import SwiftUI

struct NoColorButton: View {
  let name: LocalizedStringKey = "None"
  @Binding var isEnabled: Bool

  private var isSelected: Bool { !isEnabled }

  var body: some View {
    Button {
      isEnabled = false
    } label: {
      ZStack {
        Image(systemName: "circle")
          .foregroundColor(.secondary)
          .scaleEffect(1.05)
        Label(name, systemImage: "circle.fill")
          .foregroundStyle(.transparentColorPattern)
        Image(systemName: "circle.slash")
          .foregroundStyle(.black, .clear)
        Image(systemName: "circle")
          .opacity(isSelected ? 1 : 0)
          .scaleEffect(1.4)
      }
      .font(.title)
    }
    .accessibilityLabel(name)
  }
}

struct NoColorButton_Previews: PreviewProvider {
  static var previews: some View {
    HStack {
      NoColorButton(isEnabled: .constant(true))
      NoColorButton(isEnabled: .constant(false))
    }
    .labelStyle(.iconOnly)
  }
}
