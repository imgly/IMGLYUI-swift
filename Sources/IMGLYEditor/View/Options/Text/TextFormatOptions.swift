@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import enum IMGLYCoreUI.HorizontalAlignment
import SwiftUI

struct TextFormatOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  private var fontLibrary: FontLibrary { interactor.fontLibrary }

  var body: some View {
    List {
      if interactor.sheetContent(id) == .text {
        fontSelection
        fontWeightSelection
        fontSizeSelection
        if interactor.isAllowed(id, scope: .layerResize) {
          alignmentSelection
          frameBehavior
          clipping
        }
        letterOptions
      }
    }
  }

  // MARK: - @ViewBuilder

  @ViewBuilder var fontSelection: some View {
    let textReset = interactor.bindTextState(id, resetFontProperties: true)

    NavigationLinkPicker(title: "Font", data: [fontLibrary.assets],
                         selection: textReset.assetID) { asset, isSelected in
      Label(asset.labelOrTypefaceName ?? "Unnamed Typeface", systemImage: "checkmark")
        .labelStyle(.icon(hidden: !isSelected,
                          titleFont: .custom(asset.result.payload?.typeface?.previewFontName ?? "", size: 17)))
    } linkLabel: { selection in
      Text(selection?.labelOrTypefaceName ?? "Unnamed Typeface")
    }
  }

  @ViewBuilder var fontWeightSelection: some View {
    let text = interactor.bindTextState(id, resetFontProperties: false)

    HStack(spacing: 32) {
      PropertyButton(property: .bold, selection: text.bold)
      PropertyButton(property: .italic, selection: text.italic)
      Spacer()
      let selection: Binding<String?> = interactor.bind(id) { engine, block in
        let typeface = try engine.block.getTypeface(block)
        let styles = try engine.block.getTextFontStyles(block).first
        let weights = try engine.block.getTextFontWeights(block).first
        let currentFont = typeface.fonts.first { $0.style == styles && $0.weight == weights }
        return currentFont?.id ?? ""
      } setter: { engine, blocks, value, completion in
        let changed = try blocks.filter {
          let typeface = try engine.block.getTypeface($0)
          let styles = try engine.block.getTextFontStyles($0).first
          let weights = try engine.block.getTextFontWeights($0).first
          let currentFont = typeface.fonts.first { $0.style == styles && $0.weight == weights }
          return currentFont != nil
        }
        try changed.forEach {
          let typeface = try engine.block.getTypeface($0)
          let font = typeface.fonts.first { $0.id == value }
          if let uri = font?.uri {
            try engine.block.setFont($0, fontFileURL: uri, typeface: typeface)
          }
        }

        let didChange = !changed.isEmpty
        return try (completion?(engine, blocks, didChange) ?? false) || didChange
      }

      if let id, let fonts: [Interactor.Font] = interactor.get(id, getter: { engine, block in
        let typeface = try engine.block.getTypeface(block)
        return typeface.fonts
      }) {
        let sortedFonts = fonts.sorted { $0.weight.rawValue < $1.weight.rawValue }
        let nonItalicFonts = sortedFonts.filter { $0.style != .italic }
        let italicFonts = sortedFonts.filter { $0.style == .italic }

        NavigationLinkPicker(title: "Font Weight", data: [nonItalicFonts, italicFonts],
                             inlineTitle: false, selection: selection) { asset, isSelected in
          FontLabel(fontURL: asset.uri, isSelected: isSelected, title: .init(asset.subFamily))
        } linkLabel: { selection in
          Text(selection?.subFamily ?? "Unnamed Weight")
        }
      }
    }
    .labelStyle(.iconOnly)
    .buttonStyle(.borderless) // or .plain will do the job
  }

  @ViewBuilder var fontSizeSelection: some View {
    Section("Font Size") {
      PropertySlider<Float>("Font Size", in: 6 ... 90, property: .key(.textFontSize))
    }
  }

  @ViewBuilder var alignmentSelection: some View {
    Section("Alignment") {
      HStack(spacing: 32) {
        let alignmentX: Binding<HorizontalAlignment?> = interactor.bind(id, property: .key(.textHorizontalAlignment))
        PropertyButton(property: .left, selection: alignmentX)
        PropertyButton(property: .center, selection: alignmentX)
        PropertyButton(property: .right, selection: alignmentX)
        Spacer()
        let alignmentY: Binding<VerticalAlignment?> = interactor.bind(id, property: .key(.textVerticalAlignment))
        PropertyButton(property: .top, selection: alignmentY)
        PropertyButton(property: .center, selection: alignmentY)
        PropertyButton(property: .bottom, selection: alignmentY)
      }
      .padding([.leading, .trailing], 16)
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
    }
  }

  @ViewBuilder var frameBehavior: some View {
    let selection: Binding<TextFrameBehavior?> = interactor.bind(id) { engine, block in
      let heightMode = try engine.block.getHeightMode(block)
      switch heightMode {
      case .auto:
        let widthMode = try engine.block.getWidthMode(block)
        if widthMode == .auto {
          return .auto
        }
        return .autoHeight
      case .absolute:
        return .fixed
      default:
        return .auto
      }
    } setter: { engine, blocks, value, completion in
      let changed = try blocks.filter {
        let height = try engine.block.getHeightMode($0)
        let width = try engine.block.getWidthMode($0)
        switch value {
        case .fixed:
          return height != .absolute
        case .autoHeight:
          return height != .auto || width != .absolute
        case .auto:
          return height != .auto || width != .auto
        }
      }

      try changed.forEach {
        switch value {
        case .autoHeight:
          let width = try engine.block.getFrameWidth($0)
          try engine.block.setWidth($0, value: width)
          try engine.block.setHeightMode($0, mode: .auto)
          try engine.block.setWidthMode($0, mode: .absolute)
        case .fixed:
          let width = try engine.block.getFrameWidth($0)
          let height = try engine.block.getFrameHeight($0)
          try engine.block.setWidth($0, value: width)
          try engine.block.setHeight($0, value: height)
          try engine.block.setHeightMode($0, mode: .absolute)
          try engine.block.setWidthMode($0, mode: .absolute)
        case .auto:
          try engine.block.setHeightMode($0, mode: .auto)
          try engine.block.setWidthMode($0, mode: .auto)
        }
      }

      let didChange = !changed.isEmpty
      return try (completion?(engine, blocks, didChange) ?? false) || didChange
    }

    MenuPicker(title: "Frame Behavior", data: TextFrameBehavior.allCases, selection: selection)
  }

  @ViewBuilder var clipping: some View {
    let showClippingBinding: Binding<Bool> = interactor.bind(id, default: false) { engine, block in
      try engine.block.getHeightMode(block) == .absolute
    } setter: { _, _, _, _ in
      false
    }
    if showClippingBinding.wrappedValue {
      let clipping: Binding<Bool> = interactor.bind(id, property: .key(.textClipLinesOutsideOfFrame), default: true)
      Toggle("Clipping", isOn: clipping)
        .tint(.blue)
    }
  }

  @ViewBuilder var letterOptions: some View {
    Section("Line Height") {
      PropertySlider<Float>("Line Height", in: 0.5 ... 2.5, property: .key(.textLineHeight))
    }
    Section("Paragraph Spacing") {
      PropertySlider<Float>("Paragraph Spacing", in: 0 ... 2.5, property: .key(.textParagraphSpacing))
    }
    Section("Letter Case") {
      HStack {
        let letterCase: Binding<Interactor.TextCase?> = interactor.bind(id) { engine, block in
          let textCase = try engine.block.getTextCases(block).first
          return textCase ?? .normal
        } setter: { engine, blocks, value, completion in
          let changed = try blocks.filter {
            let textCase = try engine.block.getTextCases($0).first
            return textCase != value
          }

          try changed.forEach {
            try engine.block.setTextCase($0, textCase: value)
          }

          let didChange = !changed.isEmpty
          return try (completion?(engine, blocks, didChange) ?? false) || didChange
        }
        PropertyButton(property: .normal, selection: letterCase)
        Spacer()
        PropertyButton(property: .uppercase, selection: letterCase)
        Spacer()
        PropertyButton(property: .lowercase, selection: letterCase)
        Spacer()
        PropertyButton(property: .titlecase, selection: letterCase)
      }
      .padding([.leading, .trailing], 16)
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
    }
    Section("Letter Spacing") {
      PropertySlider<Float>("Letter Spacing", in: -0.15 ... 1.4, property: .key(.textLetterSpacing))
    }
  }
}

// MARK: - Extensions

@_spi(Internal) extension Interactor.Font: Identifiable {
  @_spi(Internal) public var id: String {
    uri.absoluteString
  }
}
