@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import enum IMGLYCoreUI.HorizontalAlignment
@_spi(Internal) import IMGLYEngine
import SwiftUI

struct TextFormatOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  private var fontLibrary: FontLibrary {
    interactor.fontLibrary
  }

  private var isTextOnPath: Bool {
    interactor.isTextOnPath(id)
  }

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
            .disabled(isTextOnPath)
          clipping
            .disabled(isTextOnPath)
        }
      }
    }
  }

  // MARK: - @ViewBuilder

  @ViewBuilder var fontSelection: some View {
    let fontAssetID = interactor.bindFontAssetID(id)

    NavigationLinkPicker(
      title: .imgly.localized("ly_img_editor_sheet_format_text_label_font"),
      data: [fontLibrary.assets],
      selection: fontAssetID,
    ) { asset, isSelected in
      FontLoader(fontURL: asset.result.payload?.typeface?.previewFont?.uri) { fontName in
        Label(asset.labelOrTypefaceName ?? "Unnamed Typeface", systemImage: "checkmark")
          .labelStyle(.icon(hidden: !isSelected, titleFont: .custom(fontName, size: 17)))
      } placeholder: {
        Label(asset.labelOrTypefaceName ?? "Unnamed Typeface", systemImage: "checkmark")
          .labelStyle(.icon(hidden: !isSelected, titleFont: .custom("", size: 17)))
      }
    } linkLabel: { selection in
      Text(selection?.labelOrTypefaceName ?? "Default")
    }
  }

  var fontWeightSelection: some View {
    HStack(spacing: 32) {
      PropertyButton(property: .bold, selection: interactor.bindBoldToggle(id))
      PropertyButton(property: .italic, selection: interactor.bindItalicToggle(id))
      PropertyButton(property: .underline, selection: interactor.bindUnderlineToggle(id))
      PropertyButton(property: .strikethrough, selection: interactor.bindStrikethroughToggle(id))
      Spacer()
      let selection: Binding<String?> = interactor.bind(
        id, default: nil as String?,
      ) { engine, block -> String? in
        try engine.block.resolveTextFontID(block)
      } setter: { engine, blocks, value, completion in
        guard let value else { return false }
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

      if let id,
         let fonts: [Interactor.Font] = interactor.get(id, getter: { engine, block in
           (try? engine.block.getTypeface(block))?.fonts ?? []
         }), !fonts.isEmpty {
        let sortedFonts = fonts.sorted { $0.weight.rawValue < $1.weight.rawValue }
        let nonItalicFonts = sortedFonts.filter { $0.style != .italic }
        let italicFonts = sortedFonts.filter { $0.style == .italic }

        NavigationLinkPicker(
          title: .imgly.localized("ly_img_editor_sheet_format_text_label_font_weight"),
          data: [nonItalicFonts, italicFonts],
          inlineTitle: false,
          selection: selection,
        ) { asset, isSelected in
          FontLabel(fontURL: asset.uri, isSelected: isSelected, title: asset.localizedSubFamiliy)
        } linkLabel: { selection in
          if let selection {
            Text(selection.localizedSubFamiliy)
          } else {
            Text(.imgly.localized("ly_img_editor_sheet_format_text_font_subfamily_mixed"))
          }
        }
      }
    }
    .labelStyle(.iconOnly)
    .buttonStyle(.borderless) // or .plain will do the job
  }

  @ViewBuilder var fontSizeSelection: some View {
    // Read the scene's font-size unit so the slider range and label match what the engine
    // returns from the unit-aware text/fontSize property.
    let fontUnit: Interactor.FontUnit = (try? interactor.engine?.scene.getFontSizeUnit()) ?? .pt
    let fontSizeRange: ClosedRange<Float> = fontUnit == .px ? 8 ... 128 : 6 ... 90
    let unitSuffix = fontUnit == .px ? " (px)" : " (pt)"
    Section {
      PropertySlider<Float>(
        .imgly.localized("ly_img_editor_sheet_format_text_label_font_size"),
        in: fontSizeRange,
        property: .key(.textFontSize),
      )
    } header: {
      Text(String(localized: .imgly.localized("ly_img_editor_sheet_format_text_label_font_size")) + unitSuffix)
    }
  }

  var alignmentSelection: some View {
    Section {
      HStack {
        let alignmentX: Binding<HorizontalAlignment?> = interactor.bind(id, property: .key(.textHorizontalAlignment))
        let effectiveAlignmentX: HorizontalAlignment? = id.flatMap { blockID in
          interactor.get(blockID) { engine, block in
            HorizontalAlignment(try engine.block.getTextEffectiveHorizontalAlignment(block))
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
              // Only use effectiveAlignment when stored alignment is Auto, because that's
              // when getTextEffectiveHorizontalAlignment resolves based on actual text direction.
              Image(
                HorizontalAlignment.auto.autoImageName(
                  forEffectiveAlignment: alignmentX.wrappedValue == .auto ? effectiveAlignmentX : nil,
                ),
                bundle: .module,
              )
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
        let letterCase = interactor.bindLetterCase(id)
        PropertyButton(property: .normal, selection: letterCase, allowsDeselection: false)
        Spacer()
        PropertyButton(property: .uppercase, selection: letterCase, allowsDeselection: false)
        Spacer()
        PropertyButton(property: .lowercase, selection: letterCase, allowsDeselection: false)
        Spacer()
        PropertyButton(property: .titlecase, selection: letterCase, allowsDeselection: false)
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
        property: .key(.textLetterSpacing),
      )
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_format_text_label_letter_spacing"))
    }
    listStyleSelection
      .disabled(isTextOnPath)
    Section {
      PropertySlider<Float>(
        .imgly.localized("ly_img_editor_sheet_format_text_label_line_height"),
        in: 0.5 ... 2.5,
        property: .key(.textLineHeight),
      )
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_format_text_label_line_height"))
    }
    .disabled(isTextOnPath)
    Section {
      PropertySlider<Float>(
        .imgly.localized("ly_img_editor_sheet_format_text_label_paragraph_spacing"),
        in: 0 ... 2.5,
        property: .key(.textParagraphSpacing),
      )
    } header: {
      Text(.imgly.localized("ly_img_editor_sheet_format_text_label_paragraph_spacing"))
    }
    .disabled(isTextOnPath)
  }

  var listStyleSelection: some View {
    Section {
      HStack {
        let listStyle = interactor.bindListStyle(id)

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
