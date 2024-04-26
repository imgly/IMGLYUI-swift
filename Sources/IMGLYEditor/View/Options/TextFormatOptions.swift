@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import enum IMGLYCoreUI.HorizontalAlignment
import SwiftUI

struct TextFormatOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  private var fontLibrary: FontLibrary { interactor.fontLibrary }

  @ViewBuilder var textFormatOptions: some View {
    let text = interactor.bindTextState(id, resetFontProperties: false)
    let textReset = interactor.bindTextState(id, resetFontProperties: true)

    NavigationLinkPicker(title: "Font", data: fontLibrary.assets,
                         selection: textReset.assetID) { asset, isSelected in
      Label(asset.labelOrTypefaceName ?? "Unnamed Typeface", systemImage: "checkmark")
        .labelStyle(.icon(hidden: !isSelected,
                          titleFont: .custom(asset.result.payload?.typeface?.previewFontName ?? "", size: 17)))
    } linkLabel: { selection in
      Text(selection?.labelOrTypefaceName ?? "Unnamed Typeface")
    }

    HStack(spacing: 32) {
      PropertyButton(property: .bold, selection: text.bold)
      PropertyButton(property: .italic, selection: text.italic)
      Spacer()
      let alignment: Binding<HorizontalAlignment?> = interactor.bind(id, property: .key(.textHorizontalAlignment))
      PropertyButton(property: .left, selection: alignment)
      PropertyButton(property: .center, selection: alignment)
      PropertyButton(property: .right, selection: alignment)
    }
    .padding([.leading, .trailing], 16)
    .labelStyle(.iconOnly)
    .buttonStyle(.borderless) // or .plain will do the job

    NavigationLink("Advanced") {
      List {
        textAdvancedOptions
      }
      .navigationTitle("Advanced Text")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          SheetDismissButton()
            .buttonStyle(.borderless)
        }
      }
    }

    Section("Font Size") {
      PropertySlider<Float>("Font Size", in: 6 ... 90, property: .key(.textFontSize))
    }
  }

  @ViewBuilder var textAdvancedOptions: some View {
    Section("Letter Spacing") {
      PropertySlider<Float>("Letter Spacing", in: -0.15 ... 1.4, property: .key(.textLetterSpacing))
    }
    Section("Line Height") {
      PropertySlider<Float>("Line Height", in: 0.5 ... 2.5, property: .key(.textLineHeight))
    }
    if interactor.isAllowed(id, scope: .layerResize) {
      PropertyStack("Vertical Alignment") {
        let alignment: Binding<VerticalAlignment?> = interactor.bind(id, property: .key(.textVerticalAlignment))
        PropertyButton(property: .top, selection: alignment)
        PropertyButton(property: .center, selection: alignment)
        PropertyButton(property: .bottom, selection: alignment)
      }
      PropertyPicker<SizeMode>("Autosize", property: .key(.heightMode),
                               cases: [
                                 .auto,
                                 .absolute
                               ]) { engine, blocks, propertyBlock, property, value, completion in
        let changed = try blocks.filter {
          try engine.block.get($0, propertyBlock, property: property) != value
        }

        try changed.forEach {
          switch value {
          case .auto:
            let width = try engine.block.getFrameWidth($0)
            try engine.block.setWidth($0, value: width)
          case .absolute:
            let width = try engine.block.getFrameWidth($0)
            let height = try engine.block.getFrameHeight($0)
            try engine.block.setWidth($0, value: width)
            try engine.block.setHeight($0, value: height)
          case .percent:
            break
          }
          try engine.block.set($0, propertyBlock, property: property, value: value)
        }

        let didChange = !changed.isEmpty
        return try (completion?(engine, blocks, didChange) ?? false) || didChange
      }
    }
  }

  var body: some View {
    List {
      if interactor.sheetType(id) == .text {
        textFormatOptions
      }
    }
  }
}
