import SwiftUI
@_spi(Internal) import IMGLYCore

/// A call-to-action button that sits next to the timeline and opens a menu.
struct AddAudioButton: View {
  let options: Timeline.AddAudioOptions
  let context: Timeline.ItemContext
  /// Replaces the button's own title when set, in both the menu and the lone-option branches.
  var title: (() -> AnyView)?
  /// Replaces the button's own icon when set, in both the menu and the lone-option branches.
  var icon: (() -> AnyView)?

  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration
  @EnvironmentObject private var editorInteractor: Interactor

  private enum Localization {
    static var buttonAddAudio: LocalizedStringResource {
      .imgly.localized("ly_img_editor_timeline_button_add_audio")
    }

    static var accessibilityAddAudio: LocalizedStringKey {
      "Add Audio Menu"
    }
  }

  var body: some View {
    buttonContent
      .frame(height: configuration.backgroundTrackHeight)
      .buttonStyle(.plain)
      .font(.caption)
      .fontWeight(.semibold)
      .background {
        RoundedRectangle(cornerRadius: configuration.cornerRadius)
          .fill(Color(uiColor: .systemGray6))
      }
      .overlay {
        RoundedRectangle(cornerRadius: configuration.cornerRadius)
          .inset(by: 0.25)
          .stroke(Color(uiColor: .separator), lineWidth: 0.5)
      }
      .fixedSize(horizontal: true, vertical: false)
  }

  /// The options that ``EditorComponent/isVisible(_:)`` allows, resolved once so the
  /// single-option shortcut below counts only options that actually appear.
  private var visibleOptions: [Timeline.AddAudioOption] {
    do {
      let options = try options(context)
      assert(
        Set(options.map(\.id)).count == options.count,
        "Timeline.Buttons.addAudio options must have unique ids; SwiftUI cannot diff duplicates.",
      )
      return try options.filter { try $0.isVisible(context) }
    } catch {
      let id = Timeline.Buttons.ID.addAudio.value
      editorInteractor.handleErrorWithTask(EditorError(
        String(localized: .imgly.localized(
          "ly_img_editor_error_editor_component_view_creation \(id) \(error.localizedDescription)",
        )),
      ))
      return []
    }
  }

  @ViewBuilder
  private var buttonContent: some View {
    let options = visibleOptions
    if options.count == 1, let option = options.first {
      // A lone option triggers directly, so the button shows that option rather than a generic
      // "Add Audio" label.
      Button { perform(option) } label: { singleOptionLabel(option) }
        .disabled(!isEnabled(option))
    } else {
      // Only the menu is labelled: the single-option branch is a plain button, and must keep the
      // option's own label so VoiceOver announces the action rather than "Add Audio Menu".
      Menu(content: { menuContent(options) }, label: menuLabel)
        .menuOrder(.fixed)
        .accessibilityLabel(Text(Localization.accessibilityAddAudio))
    }
  }

  private func menuContent(_ options: [Timeline.AddAudioOption]) -> some View {
    ForEach(options, id: \.id) { option in
      Button { perform(option) } label: { menuItemLabel(option) }
        .disabled(!isEnabled(option))
    }
  }

  /// Whether the option can be triggered. A throwing predicate leaves the option enabled, matching
  /// how a thrown visibility predicate is treated.
  private func isEnabled(_ option: Timeline.AddAudioOption) -> Bool {
    (try? option.isEnabled(context)) ?? true
  }

  private func menuItemLabel(_ option: Timeline.AddAudioOption) -> some View {
    AnyView(option.nonThrowingBody(context))
  }

  /// The lone remaining option, which names the button in place of the generic "Add Audio".
  private func singleOptionLabel(_ option: Timeline.AddAudioOption) -> some View {
    buttonLabel(
      builtInTitle: { AnyView(nonThrowing(option.title)) },
      builtInIcon: { AnyView(nonThrowing(option.icon)) },
    )
  }

  private func menuLabel() -> some View {
    buttonLabel(
      builtInTitle: { AnyView(Text(Localization.buttonAddAudio)) },
      builtInIcon: { AnyView(Image(systemName: "plus")) },
    )
  }

  /// The button's own label, laid out the same way in both branches so the button keeps its shape.
  /// An override wins over the built-in for that half alone.
  private func buttonLabel(
    builtInTitle: () -> AnyView,
    builtInIcon: () -> AnyView,
  ) -> some View {
    HStack {
      Label {
        title?() ?? builtInTitle()
      } icon: {
        icon?() ?? builtInIcon()
      }
      Spacer()
    }
    .frame(minWidth: 100)
    .frame(maxHeight: .infinity)
    .padding(.horizontal)
    .contentShape(Rectangle())
  }

  /// Reports a thrown title or icon the way a thrown option body is reported, instead of dropping it.
  private func nonThrowing(_ part: Timeline.ItemContext.To<any View>) -> some View {
    do {
      return try AnyView(part(context))
    } catch {
      editorInteractor.handleErrorWithTask(error)
      return AnyView(EmptyView())
    }
  }

  private func perform(_ option: Timeline.AddAudioOption) {
    do {
      try option.perform(context)
    } catch {
      editorInteractor.handleError(error)
    }
  }
}
