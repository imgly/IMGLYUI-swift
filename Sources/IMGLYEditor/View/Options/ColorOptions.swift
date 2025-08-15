import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct ColorOptions: View {
  private let title: LocalizedStringResource?
  private let isEnabledBinding: Binding<Bool>?
  @Binding private var color: CGColor
  private let addUndoStep: @MainActor () -> Void
  private let style: ColorPropertyButtonStyle

  init(title: LocalizedStringResource? = nil,
       isEnabled: Binding<Bool>? = nil,
       color: Binding<CGColor>,
       addUndoStep: @escaping @MainActor () -> Void = {},
       style: ColorPropertyButtonStyle = .fill) {
    self.title = title
    isEnabledBinding = isEnabled
    _color = color
    self.addUndoStep = addUndoStep
    self.style = style
  }

  @State private var showColorPicker = false
  @Environment(\.imglyColorPalette) private var colorPalette

  private var colors: [NamedColor] {
    let maxColorCount = isEnabledBinding != nil ? 6 : 7
    if colorPalette.count > maxColorCount {
      return colorPalette.dropLast(colorPalette.count - maxColorCount)
    } else {
      return colorPalette
    }
  }

  private var isEnabled: Bool { isEnabledBinding?.wrappedValue ?? true }

  var body: some View {
    let colorWithUndo: Binding<CGColor> = .init {
      color
    } set: { newValue in
      let wasEnabled = isEnabled
      let oldValue = color
      color = newValue
      if oldValue != newValue || !wasEnabled {
        addUndoStep()
      }
    }

    HStack {
      if let isEnabledBinding {
        NoColorButton(isEnabled: isEnabledBinding)
        Spacer()
      }
      ForEach(colors) {
        ColorPropertyButton(
          name: $0.name,
          color: $0.color,
          isEnabled: isEnabled,
          selection: colorWithUndo,
          style: style
        )
        Spacer()
      }

      ColorPicker("Color Picker", selection: $color)
        .labelsHidden()
        .onTapGesture {
          // Override normal tap and show custom color picker instead.
          showColorPicker = true
        }
        .imgly.colorPicker(title, isPresented: $showColorPicker, selection: $color) { started in
          if !started {
            addUndoStep()
          }
        }
        .onChange(of: showColorPicker) { newValue in
          if newValue {
            colorWithUndo.wrappedValue = color
          }
        }
    }
  }
}

struct ColorOptions_Previews: PreviewProvider {
  @State static var color: CGColor = .imgly.blue

  static var previews: some View {
    VStack {
      ColorOptions(isEnabled: .constant(true), color: $color)
      ColorOptions(isEnabled: .constant(false), color: $color)
    }
    .labelStyle(.iconOnly)
  }
}
