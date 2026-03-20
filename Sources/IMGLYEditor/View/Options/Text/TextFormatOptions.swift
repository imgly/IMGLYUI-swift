@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import enum IMGLYCoreUI.HorizontalAlignment
@_spi(Internal) import IMGLYEngine
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
        alignmentSelection
        letterOptions
        if interactor.isAllowed(id, scope: .layerResize) {
          frameBehavior
          clipping
        }
      }
    }
  }

  // MARK: - @ViewBuilder

  @ViewBuilder var fontSelection: some View {
    let textReset = interactor.bindTextState(id, resetFontProperties: true)

    NavigationLinkPicker(
      title: .imgly.localized("ly_img_editor_sheet_format_text_label_font"),
      data: [fontLibrary.assets],
      selection: textReset.assetID,
    ) { asset, isSelected in
      FontLoader(fontURL: asset.result.payload?.typeface?.previewFont?.uri) { fontName in
        Label(asset.labelOrTypefaceName ?? "Unnamed Typeface", systemImage: "checkmark")
          .labelStyle(.icon(hidden: !isSelected, titleFont: .custom(fontName, size: 17)))
      } placeholder: {
        Label(asset.labelOrTypefaceName ?? "Unnamed Typeface", systemImage: "checkmark")
          .labelStyle(.icon(hidden: !isSelected, titleFont: .custom("", size: 17)))
      }
    } linkLabel: { selection in
      Text(selection?.labelOrTypefaceName ?? "Unnamed Typeface")
    }
  }

  @ViewBuilder var fontWeightSelection: some View {
    let text = interactor.bindTextState(id, resetFontProperties: false)

    // Wrap interactor.bind to convert nil → .inactive so the setter fires on deselect.
    // GenericPropertyButton sets nil when toggling off, but interactor.bind ignores nil values.
    let rawUnderline: Binding<TextProperty?> = interactor.bind(id) { engine, block in
      let decorations = try engine.block.getTextDecorations(block)
      let hasUnderline = decorations.contains { $0.line.contains(.underline) }
      return hasUnderline ? TextProperty.underline : TextProperty.inactive
    } setter: { engine, blocks, _, completion in
      try blocks.forEach {
        try engine.block.toggleTextDecorationUnderline($0)
      }
      let didChange = !blocks.isEmpty
      return try (completion?(engine, blocks, didChange) ?? false) || didChange
    }
    let underlineBinding = Binding<TextProperty?>(
      get: { rawUnderline.wrappedValue },
      set: { rawUnderline.wrappedValue = $0 ?? .inactive }
    )

    let rawStrikethrough: Binding<TextProperty?> = interactor.bind(id) { engine, block in
      let decorations = try engine.block.getTextDecorations(block)
      let hasStrikethrough = decorations.contains { $0.line.contains(.strikethrough) }
      return hasStrikethrough ? TextProperty.strikethrough : TextProperty.inactive
    } setter: { engine, blocks, _, completion in
      try blocks.forEach {
        try engine.block.toggleTextDecorationStrikethrough($0)
      }
      let didChange = !blocks.isEmpty
      return try (completion?(engine, blocks, didChange) ?? false) || didChange
    }
    let strikethroughBinding = Binding<TextProperty?>(
      get: { rawStrikethrough.wrappedValue },
      set: { rawStrikethrough.wrappedValue = $0 ?? .inactive }
    )

    HStack(spacing: 32) {
      PropertyButton(property: .bold, selection: text.bold)
      PropertyButton(property: .italic, selection: text.italic)
      PropertyButton(property: .underline, selection: underlineBinding)
      PropertyButton(property: .strikethrough, selection: strikethroughBinding)
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
          FontLabel(fontURL: asset.uri, isSelected: isSelected, title: asset.localizedSubFamiliy)
        } linkLabel: { selection in
          if let selection {
            Text(selection.localizedSubFamiliy)
          }
        }
      }
    }
    .labelStyle(.iconOnly)
    .buttonStyle(.borderless) // or .plain will do the job
  }

  @ViewBuilder var fontSizeSelection: some View {
    Section {
      PropertySlider<Float>(
        .imgly.localized("ly_img_editor_sheet_format_text_label_font_size"),
        in: 6 ... 90,
        property: .key(.textFontSize)
      )
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_format_text_label_font_size"))
    }
  }

  @ViewBuilder var alignmentSelection: some View {
    Section {
      HStack {
        let alignmentX: Binding<HorizontalAlignment?> = interactor.bind(id, property: .key(.textHorizontalAlignment))
        let effectiveAlignmentX: HorizontalAlignment? = id.flatMap { blockID in
          interactor.get(blockID) { engine, block in
            let alignmentString = try engine.block.getTextEffectiveHorizontalAlignment(block)
            return HorizontalAlignment(rawValue: alignmentString) ?? .left
          }
        }
        HStack(spacing: 16) {
          PropertyButton(property: .left, selection: alignmentX)
          PropertyButton(property: .center, selection: alignmentX)
          PropertyButton(property: .right, selection: alignmentX)
          GenericPropertyButton(property: HorizontalAlignment.auto, selection: alignmentX) {
            Label {
              Text(HorizontalAlignment.auto.localizedStringResource)
            } icon: {
              Image(HorizontalAlignment.auto.autoImageName(forEffectiveAlignment: effectiveAlignmentX), bundle: .module)
            }
            .symbolRenderingMode(.monochrome)
          }
        }
        Spacer()
        HStack(spacing: 16) {
          let alignmentY: Binding<VerticalAlignment?> = interactor.bind(id, property: .key(.textVerticalAlignment))
          PropertyButton(property: .top, selection: alignmentY)
          PropertyButton(property: .center, selection: alignmentY)
          PropertyButton(property: .bottom, selection: alignmentY)
        }
      }
      .padding([.leading, .trailing], 16)
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_format_text_label_alignment"))
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

    MenuPicker(
      title: .imgly.localized("ly_img_editor_sheet_format_text_label_frame_behaviour"),
      data: TextFrameBehavior.allCases,
      selection: selection,
    )
  }

  @ViewBuilder var clipping: some View {
    let showClippingBinding: Binding<Bool> = interactor.bind(id, default: false) { engine, block in
      try engine.block.getHeightMode(block) == .absolute
    } setter: { _, _, _, _ in
      false
    }
    if showClippingBinding.wrappedValue {
      let clipping: Binding<Bool> = interactor.bind(id, property: .key(.textClipLinesOutsideOfFrame), default: true)
      Toggle(isOn: clipping) {
        Text(.imgly.localized("ly_img_editor_sheet_format_text_label_frame_clipping"))
      }
      .tint(.blue)
    }
  }

  @ViewBuilder var letterOptions: some View {
    Section {
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
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_format_text_label_letter_case"))
    }
    Section {
      PropertySlider<Float>(
        .imgly.localized("ly_img_editor_sheet_format_text_label_letter_spacing"),
        in: -0.15 ... 1.4,
        property: .key(.textLetterSpacing)
      )
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_format_text_label_letter_spacing"))
    }
    listStyleSelection
    Section {
      PropertySlider<Float>(
        .imgly.localized("ly_img_editor_sheet_format_text_label_line_height"),
        in: 0.5 ... 2.5,
        property: .key(.textLineHeight)
      )
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_format_text_label_line_height"))
    }
    Section {
      PropertySlider<Float>(
        .imgly.localized("ly_img_editor_sheet_format_text_label_paragraph_spacing"),
        in: 0 ... 2.5,
        property: .key(.textParagraphSpacing)
      )
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_format_text_label_paragraph_spacing"))
    }
  }

  @ViewBuilder var listStyleSelection: some View {
    Section {
      HStack {
        // Use `default: nil` overload so the getter can return nil for mixed-paragraph state.
        // This gives Binding<ListStyle?> where nil means "mixed" (no button highlighted).
        let listStyle: Binding<IMGLYEngine.ListStyle?> = interactor.bind(
          id, default: nil as IMGLYEngine.ListStyle?,
        ) { engine, block -> IMGLYEngine.ListStyle? in
          let cursorRange = try engine.block.getTextCursorRange()
          let paragraphIndices = try engine.block.getTextParagraphIndices(block, in: cursorRange)
          guard !paragraphIndices.isEmpty else { return ListStyle.none }
          let styles = try paragraphIndices.map {
            try engine.block.getTextListStyle(block, paragraphIndex: $0)
          }
          let first = styles[0]
          return styles.dropFirst().allSatisfy { $0 == first } ? first : nil
        } setter: { engine, blocks, value, completion in
          guard let value else { return false }
          let cursorRange = try engine.block.getTextCursorRange()
          let changed = try blocks.filter { block in
            let paragraphIndices = try engine.block.getTextParagraphIndices(block, in: cursorRange)
            guard !paragraphIndices.isEmpty else { return false }
            return try paragraphIndices.contains {
              try engine.block.getTextListStyle(block, paragraphIndex: $0) != value
            }
          }
          try changed.forEach { block in
            if cursorRange != nil {
              let paragraphIndices = try engine.block.getTextParagraphIndices(block, in: cursorRange)
              try paragraphIndices.forEach { index in
                try engine.block.setTextListStyle(block, listStyle: value, paragraphIndex: index)
              }
            } else {
              try engine.block.setTextListStyle(block, listStyle: value, paragraphIndex: -1)
            }
          }
          let didChange = !changed.isEmpty
          return try (completion?(engine, blocks, didChange) ?? false) || didChange
        }

        // Wrap so that PropertyButton's toggle-off (nil) maps to .none instead of mixed state.
        let mappedListStyle = Binding<IMGLYEngine.ListStyle?>(
          get: { listStyle.wrappedValue },
          set: { listStyle.wrappedValue = $0 ?? .none },
        )

        PropertyButton(property: ListStyle.none, selection: mappedListStyle)
        Spacer()
        PropertyButton(property: ListStyle.unordered, selection: mappedListStyle)
        Spacer()
        PropertyButton(property: ListStyle.ordered, selection: mappedListStyle)
      }
      .padding([.leading, .trailing], 16)
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_format_text_label_list_style"))
    }
  }
}

// MARK: - Extensions

@_spi(Internal) extension Interactor.Font: @retroactive Identifiable {
  @_spi(Internal) public var id: String {
    uri.absoluteString
  }
}
