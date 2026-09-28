import SwiftUI
@_spi(Internal) import IMGLYCore

public extension Timeline {
  /// An option shown in the timeline's "Add Audio" button.
  struct AddAudioOption: EditorComponent {
    /// A stable identifier used for diffing and ordering.
    public let id: EditorComponentID
    /// The label shown in the menu.
    let title: Timeline.ItemContext.To<any View>
    /// The icon shown in the menu.
    let icon: Timeline.ItemContext.To<any View>
    /// Whether the option is shown at all.
    let isVisible: Timeline.ItemContext.To<Bool>
    /// Whether the option can be triggered.
    let isEnabled: Timeline.ItemContext.To<Bool>
    /// Performs the option's action. A built-in option runs the timeline's own behavior unless an
    /// `action` override replaces it.
    let perform: Timeline.ItemContext.To<Void>
    /// Overrides what VoiceOver reads for the menu row, which otherwise reads ``title``. The two
    /// built-in options carry one because UI automation keys off it. A custom option gets `nil`.
    let accessibilityLabel: LocalizedStringKey?

    init(
      id: EditorComponentID,
      title: @escaping Timeline.ItemContext.To<any View>,
      icon: @escaping Timeline.ItemContext.To<any View>,
      isVisible: @escaping Timeline.ItemContext.To<Bool>,
      isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
      accessibilityLabel: LocalizedStringKey? = nil,
      perform: @escaping Timeline.ItemContext.To<Void>,
    ) {
      self.id = id
      self.title = title
      self.icon = icon
      self.isVisible = isVisible
      self.isEnabled = isEnabled
      self.accessibilityLabel = accessibilityLabel
      self.perform = perform
    }

    /// The visibility of this option.
    /// - Parameter context: The context of this option.
    /// - Returns: `true` if this option should be visible.
    public func isVisible(_ context: Timeline.ItemContext) throws -> Bool {
      try isVisible(context)
    }

    /// Whether this option can be triggered.
    /// - Parameter context: The context of this option.
    /// - Returns: `true` if this option should be enabled.
    @MainActor
    public func isEnabled(_ context: Timeline.ItemContext) throws -> Bool {
      try isEnabled(context)
    }

    /// The option's menu row. The enclosing button wraps it in the `Button` that performs the
    /// action, and reuses it as its own label when only one option remains.
    /// - Parameter context: The context of this option.
    /// - Returns: The view representation of this option.
    public func body(_ context: Timeline.ItemContext) throws -> some View {
      let title = try title(context)
      let icon = try icon(context)
      let label = Label { AnyView(title) } icon: { AnyView(icon) }
      return Group {
        if let accessibilityLabel {
          label.accessibilityLabel(Text(accessibilityLabel))
        } else {
          label
        }
      }
    }
  }
}

public extension Timeline.AddAudioOption {
  /// The stable identifiers of the built-in "Add Audio" options.
  ///
  /// Use them to find an option in an existing array, or to give a replacement the same identity.
  enum ID {
    /// The id of ``Timeline/AddAudioOption/music(action:title:icon:isEnabled:isVisible:)``.
    public static var music: EditorComponentID {
      "ly.img.component.timeline.addAudio.music"
    }

    /// The id of ``Timeline/AddAudioOption/voiceover(action:title:icon:isEnabled:isVisible:)``.
    public static var voiceover: EditorComponentID {
      "ly.img.component.timeline.addAudio.voiceover"
    }
  }

  /// Opens the audio asset library and adds the selection as an audio track.
  /// - Parameters:
  ///   - action: Replaces the built-in behavior. Pass `nil` to keep it. The built-in behavior
  /// deselects, waits for the deselect event, then opens the library in replace mode, which no
  /// ``EditorEvent`` expresses, so this is an override rather than a default.
  ///   - title: The label shown in the menu.
  ///   - icon: The icon shown in the menu.
  ///   - isEnabled: Whether the option can be triggered. By default it always can.
  ///   - isVisible: Whether the option is shown. By default it always is.
  /// - Returns: The created option.
  static func music(
    action: Timeline.ItemContext.To<Void>? = nil,
    @ViewBuilder title: @escaping Timeline.ItemContext.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_timeline_add_audio_option_music"))
    },
    @ViewBuilder icon: @escaping Timeline.ItemContext.To<some View> = { _ in
      Image.imgly.addAudio
    },
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
    isVisible: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> Timeline.AddAudioOption {
    .init(
      id: ID.music, title: title, icon: icon, isVisible: isVisible, isEnabled: isEnabled,
      accessibilityLabel: "Add Music",
    ) { context in
      if let action {
        try action(context)
      } else {
        context.interactor.addAudioAsset()
      }
    }
  }

  /// Starts a voiceover recording.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the option. By default,
  /// ``EditorEvent/openSheet(type:)`` event is invoked with sheet type ``SheetType/voiceover(style:)``.
  ///   - title: The label shown in the menu.
  ///   - icon: The icon shown in the menu.
  ///   - isEnabled: Whether the option can be triggered. By default it always can.
  ///   - isVisible: Whether the option is shown. By default it always is.
  /// - Returns: The created option.
  static func voiceover(
    action: @escaping Timeline.ItemContext.To<Void> = { $0.eventHandler.send(.openSheet(type: .voiceover())) },
    @ViewBuilder title: @escaping Timeline.ItemContext.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_timeline_add_audio_option_voiceover"))
    },
    @ViewBuilder icon: @escaping Timeline.ItemContext.To<some View> = { _ in
      Image.imgly.addVoiceover
    },
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
    isVisible: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> Timeline.AddAudioOption {
    .init(
      id: ID.voiceover, title: title, icon: icon, isVisible: isVisible, isEnabled: isEnabled,
      accessibilityLabel: "Add Voiceover", perform: action,
    )
  }

  /// A custom "Add Audio" source.
  ///
  /// The `action` receives the timeline ``Timeline/ItemContext``, so it can reach the engine, the
  /// configured asset library, and the event handler.
  /// - Parameters:
  ///   - id: A unique identifier for the option.
  ///   - action: The action to perform when the user triggers the option.
  ///   - title: The label shown in the menu.
  ///   - icon: The icon shown in the menu.
  ///   - isEnabled: Whether the option can be triggered. By default it always can.
  ///   - isVisible: Whether the option is shown. By default it always is.
  /// - Returns: The created option.
  static func custom(
    id: EditorComponentID,
    action: @escaping Timeline.ItemContext.To<Void>,
    @ViewBuilder title: @escaping Timeline.ItemContext.To<some View>,
    @ViewBuilder icon: @escaping Timeline.ItemContext.To<some View>,
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
    isVisible: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> Timeline.AddAudioOption {
    .init(id: id, title: title, icon: icon, isVisible: isVisible, isEnabled: isEnabled) { context in
      try action(context)
    }
  }
}
