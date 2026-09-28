import SwiftUI

public extension Timeline {
  /// A namespace for the built-in timeline button components.
  enum Buttons {}

  /// A namespace for the built-in timeline label components. A label displays a value and has no
  /// action, so it is not a ``Timeline/Buttons``.
  enum Labels {}
}

public extension Timeline.Buttons {
  /// The stable identifiers of the built-in timeline buttons.
  enum ID {}
}

public extension Timeline.Labels {
  /// The stable identifiers of the built-in timeline labels.
  enum ID {}
}

public extension Timeline.Labels.ID {
  /// The id of the ``Timeline/Labels/timecode(label:isEnabled:isVisible:)`` header item.
  static var timecode: EditorComponentID {
    "ly.img.component.timeline.label.timecode"
  }
}

public extension Timeline.Buttons.ID {
  /// The id of the ``Timeline/Buttons/addClip(options:title:icon:isEnabled:)`` button.
  static var addClip: EditorComponentID {
    "ly.img.component.timeline.button.addClip"
  }

  /// The id of the ``Timeline/Buttons/addAudio(options:title:icon:isEnabled:)`` button.
  static var addAudio: EditorComponentID {
    "ly.img.component.timeline.button.addAudio"
  }
}

public extension Timeline.Buttons {
  /// The default "Add Clip" button.
  ///
  /// Customize which options it offers via `options`, or replace the whole button with a
  /// ``Timeline/Custom`` in ``Timeline/Configuration``.
  ///
  /// Passing `options` replaces the menu: leave it out to keep the built-in sources and any source
  /// a future release adds.
  ///
  /// `options` is evaluated per render, so the menu can depend on the ``Timeline/ItemContext``.
  /// Returning no options — or options that are all hidden — hides the button.
  /// - Parameters:
  ///   - options: The sources the menu offers.
  ///   - title: Replaces the button's own title. Pass `nil` to keep it, which reads "Add Clip", or
  /// names the lone option when only one option is visible.
  ///   - icon: Replaces the button's own icon. Pass `nil` to keep it.
  ///   - isEnabled: Whether the button is enabled. By default it always is.
  /// - Returns: The created button.
  static func addClip(
    @Timeline.AddClipOptionsBuilder options: @escaping Timeline.AddClipOptions = { _ in [.camera(), .library()] },
    title: Timeline.ItemContext.To<any View>? = nil,
    icon: Timeline.ItemContext.To<any View>? = nil,
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> some Timeline.Item {
    Timeline.Custom(
      id: ID.addClip,
      content: { context in
        BackgroundTrackAddButton(
          options: options,
          context: context,
          title: title.map { resolve($0, in: context) },
          icon: icon.map { resolve($0, in: context) },
        )
      },
      isEnabled: isEnabled,
      // Hidden when no option would actually appear, so the button never opens an empty menu.
      isVisible: { context in try options(context).contains { try $0.isVisible(context) } },
    )
  }

  /// The default "Add Audio" button.
  ///
  /// Customize which options it offers via `options`, or replace the whole button with a
  /// ``Timeline/Custom`` in ``Timeline/Configuration``.
  ///
  /// Passing `options` replaces the menu: leave it out to keep the built-in sources and any source
  /// a future release adds.
  ///
  /// `options` is evaluated per render, so the menu can depend on the ``Timeline/ItemContext``.
  /// Returning no options — or options that are all hidden — hides the button.
  /// - Parameters:
  ///   - options: The sources the menu offers.
  ///   - title: Replaces the button's own title. Pass `nil` to keep it, which reads "Add Audio", or
  /// names the lone option when only one option is visible.
  ///   - icon: Replaces the button's own icon. Pass `nil` to keep it.
  ///   - isEnabled: Whether the button is enabled. By default it always is.
  /// - Returns: The created button.
  static func addAudio(
    @Timeline.AddAudioOptionsBuilder options: @escaping Timeline.AddAudioOptions = { _ in [.music(), .voiceover()] },
    title: Timeline.ItemContext.To<any View>? = nil,
    icon: Timeline.ItemContext.To<any View>? = nil,
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> some Timeline.Item {
    Timeline.Custom(
      id: ID.addAudio,
      content: { context in
        AddAudioButton(
          options: options,
          context: context,
          title: title.map { resolve($0, in: context) },
          icon: icon.map { resolve($0, in: context) },
        )
      },
      isEnabled: isEnabled,
      // Hidden when no option would actually appear, so the button never opens an empty menu.
      isVisible: { context in try options(context).contains { try $0.isVisible(context) } },
    )
  }
}

public extension Timeline.Buttons.ID {
  /// The id of the ``Timeline/Buttons/playPause(action:icon:isEnabled:isVisible:)`` header item.
  static var playPause: EditorComponentID {
    "ly.img.component.timeline.button.playPause"
  }

  /// The id of the ``Timeline/Buttons/loop(action:icon:isEnabled:isVisible:)`` header item.
  static var loop: EditorComponentID {
    "ly.img.component.timeline.button.loop"
  }

  /// The id of the ``Timeline/Buttons/toggleExpanded(action:label:isEnabled:isVisible:)`` header item.
  static var toggleExpanded: EditorComponentID {
    "ly.img.component.timeline.button.toggleExpanded"
  }
}

public extension Timeline {
  /// Flexible space between header items.
  ///
  /// Placement alone only groups items; a spacer is what pushes them apart.
  /// - Note: The id is not unique: a header can hold more than one spacer, so a spacer's position
  /// within its ``Timeline/ItemPlacement`` group is part of its identity. That position only exists
  /// once the header renders, so the id cannot anchor a
  /// ``Timeline/Configuration/Builder/modifyHeader(_:)`` operation — it would match whichever spacer
  /// is reached first. Restate the header instead.
  struct Spacer: Item {
    public let id: EditorComponentID = .init("ly.img.component.timeline.spacer", isUnique: false)

    private let visibility: Timeline.ItemContext.To<Bool>

    /// Creates a spacer.
    /// - Parameter isVisible: Whether the spacer is present. By default it always is.
    public init(isVisible: @escaping Timeline.ItemContext.To<Bool> = { _ in true }) {
      visibility = isVisible
    }

    public func isVisible(_ context: Timeline.ItemContext) throws -> Bool {
      try visibility(context)
    }

    public func body(_: Timeline.ItemContext) throws -> some View {
      SwiftUI.Spacer()
    }
  }
}

/// Runs a header item's action override, reporting a thrown error the way the other configurable
/// editor buttons do instead of dropping it.
@MainActor
private func perform(_ action: Timeline.ItemContext.To<Void>, in context: Timeline.ItemContext) {
  do {
    try action(context)
  } catch {
    (context.eventHandler as? Interactor)?.handleError(error)
  }
}

/// Resolves a header item's title, icon or label override, reporting a thrown error the way a
/// thrown action does instead of dropping it.
@MainActor
private func resolve(
  _ part: @escaping Timeline.ItemContext.To<any View>,
  in context: Timeline.ItemContext,
) -> () -> AnyView {
  {
    do {
      return try AnyView(part(context))
    } catch {
      (context.eventHandler as? Interactor)?.handleError(error)
      return AnyView(EmptyView())
    }
  }
}

public extension Timeline.Labels {
  /// The default timecode display, showing the playhead position and the total duration.
  /// - Parameters:
  ///   - label: Replaces the built-in timecode display. Pass `nil` to keep it.
  ///   - isEnabled: Whether the item is enabled. By default it always is.
  ///   - isVisible: Whether the item is visible. By default it always is.
  /// - Returns: The created item.
  static func timecode(
    label: Timeline.ItemContext.To<any View>? = nil,
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
    isVisible: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> some Timeline.Item {
    Timeline.Custom(
      id: ID.timecode,
      content: { context in TimelineTimecodeItem(label: label.map { resolve($0, in: context) }) },
      isEnabled: isEnabled,
      isVisible: isVisible,
    )
  }
}

public extension Timeline.Buttons {
  /// The default play/pause button.
  /// - Parameters:
  ///   - action: Replaces the built-in play/pause behavior. Pass `nil` to keep it.
  ///   - icon: Replaces the built-in play/pause glyph. Pass `nil` to keep it.
  ///   - isEnabled: Whether the button is enabled. By default it always is.
  ///   - isVisible: Whether the button is visible. By default it always is.
  /// - Returns: The created button.
  static func playPause(
    action: Timeline.ItemContext.To<Void>? = nil,
    icon: Timeline.ItemContext.To<any View>? = nil,
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
    isVisible: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> some Timeline.Item {
    Timeline.Custom(
      id: ID.playPause,
      content: { context in
        TimelinePlayPauseItem(
          action: action.map { action in { perform(action, in: context) } },
          icon: icon.map { resolve($0, in: context) },
        )
      },
      isEnabled: isEnabled,
      isVisible: isVisible,
    )
  }

  /// The default looping toggle.
  /// - Parameters:
  ///   - action: Replaces the built-in looping toggle. Pass `nil` to keep it.
  ///   - icon: Replaces the built-in looping icons with one that does not change with the looping
  /// state. Pass `nil` to keep them.
  ///   - isEnabled: Whether the button is enabled. By default it always is.
  ///   - isVisible: Whether the button is visible. By default it always is.
  /// - Returns: The created button.
  static func loop(
    action: Timeline.ItemContext.To<Void>? = nil,
    icon: Timeline.ItemContext.To<any View>? = nil,
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
    isVisible: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> some Timeline.Item {
    Timeline.Custom(
      id: ID.loop,
      content: { context in
        TimelineLoopItem(
          action: action.map { action in { perform(action, in: context) } },
          icon: icon.map { resolve($0, in: context) },
        )
      },
      isEnabled: isEnabled,
      isVisible: isVisible,
    )
  }

  /// The default expand/collapse toggle.
  /// - Parameters:
  ///   - action: Replaces the built-in expand/collapse behavior. Pass `nil` to keep it.
  ///   - label: Replaces the built-in expand/collapse label. Pass `nil` to keep it.
  ///   - isEnabled: Whether the button is enabled. By default it always is.
  ///   - isVisible: Whether the button is visible. By default it is hidden in a compact vertical
  /// size class, matching the timeline's built-in behavior.
  /// - Returns: The created button.
  static func toggleExpanded(
    action: Timeline.ItemContext.To<Void>? = nil,
    label: Timeline.ItemContext.To<any View>? = nil,
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
    isVisible: @escaping Timeline.ItemContext.To<Bool> = { $0.verticalSizeClass != .compact },
  ) -> some Timeline.Item {
    Timeline.Custom(
      id: ID.toggleExpanded,
      content: { context in
        TimelineToggleExpandedItem(
          action: action.map { action in { perform(action, in: context) } },
          label: label.map { resolve($0, in: context) },
        )
      },
      isEnabled: isEnabled,
      isVisible: isVisible,
    )
  }
}
