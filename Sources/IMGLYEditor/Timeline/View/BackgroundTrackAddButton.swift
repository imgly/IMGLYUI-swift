import SwiftUI
@_spi(Internal) import IMGLYCore

/// A call-to-action button that sits next to the timeline and opens a menu.
struct BackgroundTrackAddButton: View {
  let options: Timeline.AddClipOptions
  let context: Timeline.ItemContext
  /// Replaces the button's own title when set, in both the menu and the lone-option branches.
  var title: (() -> AnyView)?
  /// Replaces the button's own icon when set, in both the menu and the lone-option branches.
  var icon: (() -> AnyView)?

  @EnvironmentObject private var editorInteractor: Interactor
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  var body: some View {
    buttonContent
      .padding(.horizontal)
      .frame(height: configuration.backgroundTrackHeight)
      .buttonStyle(.plain)
      .font(.caption)
      .fontWeight(.semibold)
      .background(buttonBackground)
      .overlay(buttonBorder)
      .fixedSize(horizontal: true, vertical: false)
  }

  // MARK: - Button Content

  /// The options that ``EditorComponent/isVisible(_:)`` allows, resolved once so the
  /// single-option shortcut below counts only options that actually appear.
  private var visibleOptions: [Timeline.AddClipOption] {
    do {
      let options = try options(context)
      assert(
        Set(options.map(\.id)).count == options.count,
        "Timeline.Buttons.addClip options must have unique ids; SwiftUI cannot diff duplicates.",
      )
      return try options.filter { try $0.isVisible(context) }
    } catch {
      let id = Timeline.Buttons.ID.addClip.value
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
      // "Add Clip" label.
      Button { perform(option) } label: { singleOptionLabel(option) }
        .disabled(!isEnabled(option))
    } else {
      multipleOptionsMenu(options)
    }
  }

  // MARK: - Button Components

  private func multipleOptionsMenu(_ options: [Timeline.AddClipOption]) -> some View {
    Menu(content: {
      ForEach(options, id: \.id) { option in
        menuItem(for: option)
      }
    }, label: {
      buttonLabel
    })
    .menuOrder(.fixed)
  }

  private var buttonLabel: some View {
    buttonLabel(
      builtInTitle: { AnyView(Text(.imgly.localized("ly_img_editor_timeline_button_add_clip"))) },
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
    .contentShape(Rectangle())
  }

  private var buttonBackground: some View {
    RoundedRectangle(cornerRadius: configuration.cornerRadius)
      .fill(Color(uiColor: .systemGray6))
  }

  private var buttonBorder: some View {
    RoundedRectangle(cornerRadius: configuration.cornerRadius)
      .inset(by: 0.25)
      .stroke(Color(uiColor: .separator), lineWidth: 0.5)
  }

  // MARK: - Actions

  private func perform(_ option: Timeline.AddClipOption) {
    do {
      try option.perform(context)
    } catch {
      editorInteractor.handleError(error)
    }
  }

  private func menuItem(for option: Timeline.AddClipOption) -> some View {
    Button { perform(option) } label: { optionLabel(for: option) }
      .disabled(!isEnabled(option))
  }

  /// Whether the option can be triggered. A throwing predicate leaves the option enabled, matching
  /// how a thrown visibility predicate is treated.
  private func isEnabled(_ option: Timeline.AddClipOption) -> Bool {
    (try? option.isEnabled(context)) ?? true
  }

  private func optionLabel(for option: Timeline.AddClipOption) -> some View {
    AnyView(option.nonThrowingBody(context))
  }

  /// The lone remaining option, which names the button in place of the generic "Add Clip".
  private func singleOptionLabel(_ option: Timeline.AddClipOption) -> some View {
    buttonLabel(
      builtInTitle: { AnyView(nonThrowing(option.title)) },
      builtInIcon: { AnyView(nonThrowing(option.icon)) },
    )
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
}
