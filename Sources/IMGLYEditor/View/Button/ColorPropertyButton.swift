import SwiftUI
@_spi(Internal) import IMGLYCoreUI

enum ColorPropertyButtonStyle {
  case fill
  case stroke
}

struct ColorPropertyButton: View {
  let name: LocalizedStringResource
  let color: CGColor
  let isEnabled: Bool
  /// The distinct colours of the current selection; the button is marked selected only when the
  /// selection is uniformly its colour.
  @Binding var selection: [CGColor]
  var style: ColorPropertyButtonStyle = .fill

  private var isSelected: Bool {
    guard isEnabled, selection.count == 1, let selectionColor = selection.first,
          let rgba = try? color.rgba(), let selectionRGBA = try? selectionColor.rgba() else {
      return false
    }
    return selectionRGBA == rgba
  }

  var body: some View {
    Button {
      selection = [color]
    } label: {
      ZStack {
        Image(systemName: "circle")
          .foregroundColor(.secondary)
          .scaleEffect(1.05)
        if style == .fill {
          Label {
            Text(name)
          } icon: {
            Image(systemName: "circle.fill")
          }
          .foregroundStyle(Color(cgColor: color))
        } else {
          Image("custom.circle.circle.fill", bundle: .module)
            .foregroundColor(.secondary)
            .scaleEffect(0.9)
          Image("custom.circle.circle.fill", bundle: .module)
            .foregroundStyle(.transparentColorPattern)
          Image("custom.circle.circle.fill", bundle: .module)
            .foregroundStyle(Color(cgColor: color))
        }
        Image(systemName: "circle")
          .opacity(isSelected ? 1 : 0)
          .scaleEffect(1.4)
      }
      .font(.title)
    }
    .accessibilityLabel(Text(name))
  }
}

struct ColorPropertyButton_Previews: PreviewProvider {
  @State static var selection: [CGColor] = [.imgly.blue]

  static var previews: some View {
    HStack {
      ColorPropertyButton(name: "Blue", color: .imgly.blue, isEnabled: true, selection: $selection)
      ColorPropertyButton(name: "Blue", color: .imgly.blue, isEnabled: false, selection: $selection)
      ColorPropertyButton(name: "Yellow", color: .imgly.yellow, isEnabled: true, selection: $selection)
    }
    .labelStyle(.iconOnly)
  }
}
