@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYEngine
import SwiftUI

struct KeyboardToolbar: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    // Hidden while the keyboard is suspended (handed off to a sheet) even though text-edit mode
    // stays active, so the toolbar doesn't drop behind the sheet.
    if interactor.editMode == .text, !isSoftwareKeyboardSuspended {
      content
        .background {
          GeometryReader { geo in
            Color.clear
              .preference(
                key: KeyboardToolbarSafeAreaInsetsKey.self,
                value: EdgeInsets(top: geo.size.height, leading: 0, bottom: 0, trailing: 0),
              )
          }
        }
    }
  }

  private var isSoftwareKeyboardSuspended: Bool {
    (try? interactor.engine?.editor.getSettingBool("softwareKeyboardSuspended")) == true
  }

  @ViewBuilder private var content: some View {
    let bar = islands
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
    if #available(iOS 26.0, *), !usesLegacyDesign {
      bar
    } else {
      bar
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
  }

  @ViewBuilder private var islands: some View {
    if #available(iOS 26.0, *), !usesLegacyDesign {
      GlassEffectContainer(spacing: 8) {
        islandStack
      }
    } else {
      islandStack
    }
  }

  @ViewBuilder private var islandStack: some View {
    if isFormattingAllowed {
      HStack(spacing: 8) {
        formattingIsland
        doneIsland
      }
    } else {
      disabledStack
    }
  }

  @ViewBuilder private var disabledStack: some View {
    if #available(iOS 26.0, *), !usesLegacyDesign {
      HStack(spacing: 8) {
        disabledIsland
        doneIsland
      }
    } else {
      disabledIsland
        .overlay(alignment: .trailing) {
          doneIsland
        }
    }
  }

  private var formattingIsland: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        TextColorSwatch(blockID: id)
        BoldToggle(blockID: id)
        ItalicToggle(blockID: id)
        UnderlineToggle(blockID: id)
        StrikethroughToggle(blockID: id)
        LetterCaseMenu(blockID: id)
        ListStyleMenu(blockID: id)
      }
      .padding(.horizontal, 8)
    }
    .modifier(IslandChrome(usesLegacyDesign: usesLegacyDesign))
  }

  private var disabledIsland: some View {
    Text(.imgly.localized("ly_img_editor_edit_text_title"))
      .font(.body.weight(.semibold))
      .frame(maxWidth: .infinity)
      .frame(height: islandHeight)
      .modifier(IslandChrome(usesLegacyDesign: usesLegacyDesign))
  }

  private var doneIsland: some View {
    doneButton
      .modifier(IslandChrome(usesLegacyDesign: usesLegacyDesign))
  }

  @ViewBuilder private var doneButton: some View {
    let button = Button {
      interactor.keyboardBarDismissButtonTapped()
    } label: {
      Text(.imgly.localized("ly_img_editor_common_button_done"))
        .font(.body.weight(.semibold))
        .padding(.horizontal, 16)
        .frame(height: islandHeight)
    }
    .buttonStyle(.plain)
    if #available(iOS 26.0, *), !usesLegacyDesign {
      button
        .foregroundStyle(Color.primary)
    } else {
      button
        .foregroundStyle(Color.accentColor)
    }
  }

  private let islandHeight: CGFloat = 44

  private var isFormattingAllowed: Bool {
    guard let id else { return false }
    return interactor.get(id) { engine, block in
      try engine.block.isAllowedByScope(block, key: "text/character")
    } ?? false
  }
}

// MARK: - Keyboard bar chrome

private struct IslandChrome: ViewModifier {
  let usesLegacyDesign: Bool

  @ViewBuilder func body(content: Content) -> some View {
    if #available(iOS 26.0, *), !usesLegacyDesign {
      content
        .glassEffect(.regular.interactive(), in: Capsule())
    } else {
      content
    }
  }
}

// MARK: - Color swatch

private struct TextColorSwatch: View {
  @EnvironmentObject private var interactor: Interactor

  let blockID: Interactor.BlockID?

  var body: some View {
    Button {
      // Suspend the soft keyboard so it resigns while text-edit mode stays alive. Reset on sheet close.
      try? interactor.engine?.editor.setSettingBool("softwareKeyboardSuspended", value: true)
      // Small detent — the fill-only sheet is just a type picker and one colour row.
      interactor.send(.openSheet(type: .fillStroke(style: .only(detent: .imgly.small), fillOnly: true)))
    } label: {
      FillColorImage(isEnabled: true, colors: .constant(colors), multiColorStyle: .stripes)
        .font(.title3)
        .frame(width: 28, height: 28)
    }
    .buttonStyle(.plain)
    .frame(width: 44, height: 44)
  }

  /// Every colour across the effective text range, so the swatch can stack mixed colours.
  private var colors: [CGColor] {
    guard let blockID else { return [CGColor.imgly.black] }
    let resolved = interactor.get(blockID) { engine, block -> [CGColor] in
      let range = try engine.block.effectiveTextRange(block)
      return try engine.block.getTextColors(block, in: range).compactMap(\.cgColor)
    } ?? []
    return resolved.isEmpty ? [CGColor.imgly.black] : resolved
  }
}

// MARK: - Bold / Italic toggles

private struct BoldToggle: View {
  @EnvironmentObject private var interactor: Interactor

  let blockID: Interactor.BlockID?

  var body: some View {
    PropertyButton(property: .bold, selection: interactor.bindBoldToggle(blockID))
      .modifier(FormattingButtonStyle())
  }
}

private struct ItalicToggle: View {
  @EnvironmentObject private var interactor: Interactor

  let blockID: Interactor.BlockID?

  var body: some View {
    PropertyButton(property: .italic, selection: interactor.bindItalicToggle(blockID))
      .modifier(FormattingButtonStyle())
  }
}

// MARK: - Underline / Strikethrough toggles

private struct UnderlineToggle: View {
  @EnvironmentObject private var interactor: Interactor

  let blockID: Interactor.BlockID?

  var body: some View {
    PropertyButton(property: .underline, selection: interactor.bindUnderlineToggle(blockID))
      .modifier(FormattingButtonStyle())
  }
}

private struct StrikethroughToggle: View {
  @EnvironmentObject private var interactor: Interactor

  let blockID: Interactor.BlockID?

  var body: some View {
    PropertyButton(property: .strikethrough, selection: interactor.bindStrikethroughToggle(blockID))
      .modifier(FormattingButtonStyle())
  }
}

// MARK: - Letter case menu

private struct LetterCaseMenu: View {
  @EnvironmentObject private var interactor: Interactor

  let blockID: Interactor.BlockID?

  var body: some View {
    let selection = interactor.bindLetterCase(blockID)
    let current = selection.wrappedValue
    let active = current.map { $0 != .normal } ?? false
    let restingCase: TextCase = switch current {
    case .lowercase: .lowercase
    case .titlecase: .titlecase
    default: .uppercase
    }

    FormattingMenuButton(
      accessibilityLabelKey: "ly_img_editor_edit_text_label_letter_case",
      options: [
        FormattingOption(
          labelKey: "ly_img_editor_edit_text_letter_case_option_none",
          isSelected: current == .normal,
          action: { selection.wrappedValue = .normal },
          icon: { Image(systemName: "textformat") },
        ),
        FormattingOption(
          labelKey: "ly_img_editor_edit_text_letter_case_option_uppercase",
          isSelected: current == .uppercase,
          action: { selection.wrappedValue = .uppercase },
          icon: { TextCase.uppercase.icon },
        ),
        FormattingOption(
          labelKey: "ly_img_editor_edit_text_letter_case_option_lowercase",
          isSelected: current == .lowercase,
          action: { selection.wrappedValue = .lowercase },
          icon: { TextCase.lowercase.icon },
        ),
        FormattingOption(
          labelKey: "ly_img_editor_edit_text_letter_case_option_title_case",
          isSelected: current == .titlecase,
          action: { selection.wrappedValue = .titlecase },
          icon: { TextCase.titlecase.icon },
        ),
      ],
    ) {
      restingCase.icon
        .foregroundColor(active ? .accentColor : .primary)
    }
  }
}

// MARK: - List style menu

private struct ListStyleMenu: View {
  @EnvironmentObject private var interactor: Interactor

  let blockID: Interactor.BlockID?

  var body: some View {
    let selection = interactor.bindListStyle(blockID)
    let active = selection.wrappedValue.map { $0 != IMGLYEngine.ListStyle.none } ?? false
    let restingStyle: IMGLYEngine.ListStyle = selection.wrappedValue == .ordered ? .ordered : .unordered

    FormattingMenuButton(
      accessibilityLabelKey: "ly_img_editor_edit_text_label_list_style",
      options: [
        FormattingOption(
          labelKey: "ly_img_editor_edit_text_list_style_option_none",
          isSelected: selection.wrappedValue == IMGLYEngine.ListStyle.none,
          action: { selection.wrappedValue = IMGLYEngine.ListStyle.none },
          icon: { Image(systemName: "minus") },
        ),
        FormattingOption(
          labelKey: "ly_img_editor_edit_text_list_style_option_bulleted",
          isSelected: selection.wrappedValue == .unordered,
          action: { selection.wrappedValue = .unordered },
          icon: { IMGLYEngine.ListStyle.unordered.icon },
        ),
        FormattingOption(
          labelKey: "ly_img_editor_edit_text_list_style_option_numbered",
          isSelected: selection.wrappedValue == .ordered,
          action: { selection.wrappedValue = .ordered },
          icon: { IMGLYEngine.ListStyle.ordered.icon },
        ),
      ],
    ) {
      restingStyle.icon
        .foregroundColor(active ? .accentColor : .primary)
    }
  }
}

// MARK: - Helpers

private struct FormattingOption {
  let labelKey: String.LocalizationValue
  let isSelected: Bool
  let action: () -> Void
  let icon: AnyView

  init(
    labelKey: String.LocalizationValue,
    isSelected: Bool,
    action: @escaping () -> Void,
    @ViewBuilder icon: () -> some View,
  ) {
    self.labelKey = labelKey
    self.isSelected = isSelected
    self.action = action
    self.icon = AnyView(icon())
  }
}

/// A formatting control with selectable options. Liquid Glass presents them in a popover rather than a system
/// `Menu` to avoid the re-resolve flash that `UIMenu` causes by snapshotting its source; the legacy design keeps
/// the native `Menu` (no Liquid Glass, and no compact popover adaptation before 16.4).
private struct FormattingMenuButton<TriggerLabel: View>: View {
  let accessibilityLabelKey: String.LocalizationValue
  let options: [FormattingOption]
  @ViewBuilder var label: () -> TriggerLabel

  @State private var isPresented = false

  var body: some View {
    control
      .modifier(FormattingButtonStyle())
      .accessibilityLabel(Text(.imgly.localized(accessibilityLabelKey)))
  }

  @ViewBuilder private var control: some View {
    if #available(iOS 26.0, *), !usesLegacyDesign {
      popoverControl
    } else {
      menuControl
    }
  }

  @available(iOS 26.0, *)
  private var popoverControl: some View {
    Button {
      isPresented = true
    } label: {
      label()
    }
    .popover(isPresented: $isPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
      FormattingPopoverContent {
        ForEach(0 ..< options.count, id: \.self) { index in
          PopoverMenuRow(option: options[index])
        }
      }
      .presentationCompactAdaptation(.popover)
    }
  }

  private var menuControl: some View {
    Menu {
      ForEach(0 ..< options.count, id: \.self) { index in
        let option = options[index]
        Button(action: option.action) {
          Label {
            Text(.imgly.localized(option.labelKey))
          } icon: {
            option.icon
          }
          if option.isSelected {
            Image(systemName: "checkmark")
          }
        }
      }
    } label: {
      label()
    }
  }
}

private struct FormattingButtonStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .labelStyle(.iconOnly)
      .buttonStyle(.plain)
      .font(.body)
      .frame(width: 40, height: 44)
  }
}

private let formattingPopoverMinWidth: CGFloat = 220

private struct FormattingPopoverContent<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      content()
    }
    .buttonStyle(.plain)
    .padding(.vertical, 6)
    .frame(minWidth: formattingPopoverMinWidth, alignment: .leading)
  }
}

private struct PopoverMenuRow: View {
  @Environment(\.dismiss) private var dismiss

  let option: FormattingOption

  var body: some View {
    Button {
      option.action()
      dismiss()
    } label: {
      HStack(spacing: 12) {
        option.icon
          .frame(width: 24)
        Text(.imgly.localized(option.labelKey))
          .frame(maxWidth: .infinity, alignment: .leading)
        Image(systemName: "checkmark")
          .font(.body.weight(.semibold))
          .frame(width: 16)
          .opacity(option.isSelected ? 1 : 0)
          .accessibilityHidden(true)
      }
      .foregroundStyle(Color.primary)
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .contentShape(Rectangle())
    }
    .accessibilityAddTraits(option.isSelected ? .isSelected : [])
  }
}
