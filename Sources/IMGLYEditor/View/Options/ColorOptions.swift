import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct ColorOptions: View {
  private let title: LocalizedStringResource?
  private let isEnabledBinding: Binding<Bool>?
  /// The distinct colours of the bound selection. A single colour marks the matching preset as
  /// selected; several (a mixed text selection) mark none. Setting always writes one uniform colour.
  @Binding private var colors: [CGColor]
  private let addUndoStep: @MainActor () -> Void
  private let style: ColorPropertyButtonStyle

  init(title: LocalizedStringResource? = nil,
       isEnabled: Binding<Bool>? = nil,
       colors: Binding<[CGColor]>,
       addUndoStep: @escaping @MainActor () -> Void = {},
       style: ColorPropertyButtonStyle = .fill) {
    self.title = title
    isEnabledBinding = isEnabled
    _colors = colors
    self.addUndoStep = addUndoStep
    self.style = style
  }

  /// Convenience for call sites bound to a single colour.
  init(title: LocalizedStringResource? = nil,
       isEnabled: Binding<Bool>? = nil,
       color: Binding<CGColor>,
       addUndoStep: @escaping @MainActor () -> Void = {},
       style: ColorPropertyButtonStyle = .fill) {
    let colors = Binding<[CGColor]> {
      [color.wrappedValue]
    } set: { newValue in
      guard let newColor = newValue.first else { return }
      color.wrappedValue = newColor
    }
    self.init(title: title, isEnabled: isEnabled, colors: colors, addUndoStep: addUndoStep, style: style)
  }

  @State private var showColorPicker = false
  @Environment(\.imglyEditorEnvironment) private var editorEnvironment

  private var colorPalette: [NamedColor] {
    editorEnvironment.colorPalette ?? ColorPalette.defaultValue
  }

  private var presetColors: [NamedColor] {
    let maxColorCount = isEnabledBinding != nil ? 6 : 7
    if colorPalette.count > maxColorCount {
      return colorPalette.dropLast(colorPalette.count - maxColorCount)
    } else {
      return colorPalette
    }
  }

  private var isEnabled: Bool { isEnabledBinding?.wrappedValue ?? true }

  /// Single-colour view onto `colors` for the colour pickers; a mixed selection shows its first colour.
  private var color: Binding<CGColor> {
    .init {
      colors.first ?? .imgly.black
    } set: { newValue in
      colors = [newValue]
    }
  }

  var body: some View {
    let colorsWithUndo: Binding<[CGColor]> = .init {
      colors
    } set: { newValue in
      let wasEnabled = isEnabled
      let oldValue = colors
      colors = newValue
      if oldValue != newValue || !wasEnabled {
        addUndoStep()
      }
    }

    HStack {
      if let isEnabledBinding {
        NoColorButton(isEnabled: isEnabledBinding)
        Spacer()
      }
      ForEach(presetColors) {
        ColorPropertyButton(
          name: $0.name,
          color: $0.color,
          isEnabled: isEnabled,
          selection: colorsWithUndo,
          style: style,
        )
        Spacer()
      }

      ColorPicker("Color Picker", selection: color)
        .labelsHidden()
        .onTapGesture {
          // Override normal tap and show custom color picker instead.
          showColorPicker = true
        }
        .imgly.colorPicker(title, isPresented: $showColorPicker, selection: color) { started in
          if !started {
            addUndoStep()
          }
        }
        .onChange(of: showColorPicker) { newValue in
          if newValue {
            colorsWithUndo.wrappedValue = colors
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
