import SwiftUI
@_spi(Internal) import IMGLYCore

public extension Timeline {
  /// An option shown in the timeline's "Add Clip" button.
  struct AddClipOption: EditorComponent {
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

    init(
      id: EditorComponentID,
      title: @escaping Timeline.ItemContext.To<any View>,
      icon: @escaping Timeline.ItemContext.To<any View>,
      isVisible: @escaping Timeline.ItemContext.To<Bool>,
      isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
      perform: @escaping Timeline.ItemContext.To<Void>,
    ) {
      self.id = id
      self.title = title
      self.icon = icon
      self.isVisible = isVisible
      self.isEnabled = isEnabled
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
      return Label { AnyView(title) } icon: { AnyView(icon) }
    }
  }
}

public extension Timeline.AddClipOption {
  /// The stable identifiers of the built-in "Add Clip" options.
  ///
  /// Use them to find an option in an existing array, or to give a replacement the same identity.
  enum ID {
    /// The id of ``Timeline/AddClipOption/camera(action:title:icon:isEnabled:isVisible:)``.
    public static var camera: EditorComponentID {
      "ly.img.component.timeline.addClip.camera"
    }

    /// The id of ``Timeline/AddClipOption/photoRoll(action:title:icon:isEnabled:isVisible:)``.
    public static var photoRoll: EditorComponentID {
      "ly.img.component.timeline.addClip.photoRoll"
    }

    /// The id of ``Timeline/AddClipOption/library(action:title:icon:isEnabled:isVisible:)``.
    public static var library: EditorComponentID {
      "ly.img.component.timeline.addClip.library"
    }
  }

  /// Records a clip with the camera and adds it to the background track.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the option. By default,
  /// ``EditorEvent/addFromIMGLYCamera(to:)`` event is invoked.
  ///   - title: The label shown in the menu.
  ///   - icon: The icon shown in the menu.
  ///   - isEnabled: Whether the option can be triggered. By default it always can.
  ///   - isVisible: Whether the option is shown. By default it always is.
  /// - Returns: The created option.
  static func camera(
    action: @escaping Timeline.ItemContext.To<Void> = { $0.eventHandler.send(.addFromIMGLYCamera()) },
    @ViewBuilder title: @escaping Timeline.ItemContext.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_timeline_add_clip_option_camera"))
    },
    @ViewBuilder icon: @escaping Timeline.ItemContext.To<some View> = { _ in
      Image.imgly.addCameraBackground
    },
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
    isVisible: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> Timeline.AddClipOption {
    .init(id: ID.camera, title: title, icon: icon, isVisible: isVisible, isEnabled: isEnabled, perform: action)
  }

  /// Opens the privacy-friendly photo picker and adds the selection to the background track.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the option. By default,
  /// ``EditorEvent/addFromPhotoRoll(addToBackgroundTrack:)`` event is invoked.
  ///   - title: The label shown in the menu.
  ///   - icon: The icon shown in the menu.
  ///   - isEnabled: Whether the option can be triggered. By default it always can.
  ///   - isVisible: Whether the option is shown. By default it always is.
  /// - Returns: The created option.
  static func photoRoll(
    action: @escaping Timeline.ItemContext.To<Void> = {
      $0.eventHandler.send(.addFromPhotoRoll(addToBackgroundTrack: true))
    },
    @ViewBuilder title: @escaping Timeline.ItemContext.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_photo_roll"))
    },
    @ViewBuilder icon: @escaping Timeline.ItemContext.To<some View> = { _ in
      Image.imgly.addPhotoRollBackground
    },
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
    isVisible: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> Timeline.AddClipOption {
    .init(id: ID.photoRoll, title: title, icon: icon, isVisible: isVisible, isEnabled: isEnabled, perform: action)
  }

  /// Opens the asset library and adds the selection to the background track.
  /// - Parameters:
  ///   - action: Replaces the built-in behavior. Pass `nil` to keep it. The built-in behavior opens
  /// the library in replace mode against the background track, which no ``EditorEvent`` expresses,
  /// so this is an override rather than a default.
  ///   - title: The label shown in the menu.
  ///   - icon: The icon shown in the menu.
  ///   - isEnabled: Whether the option can be triggered. By default it always can.
  ///   - isVisible: Whether the option is shown. By default it always is.
  /// - Returns: The created option.
  static func library(
    action: Timeline.ItemContext.To<Void>? = nil,
    @ViewBuilder title: @escaping Timeline.ItemContext.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_timeline_add_clip_option_library"))
    },
    @ViewBuilder icon: @escaping Timeline.ItemContext.To<some View> = { _ in
      Image.imgly.addClipLibrary
    },
    isEnabled: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
    isVisible: @escaping Timeline.ItemContext.To<Bool> = { _ in true },
  ) -> Timeline.AddClipOption {
    .init(id: ID.library, title: title, icon: icon, isVisible: isVisible, isEnabled: isEnabled) { context in
      if let action {
        try action(context)
      } else {
        context.interactor.addAssetToBackgroundTrack()
      }
    }
  }

  /// A custom "Add Clip" source.
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
  ) -> Timeline.AddClipOption {
    .init(id: id, title: title, icon: icon, isVisible: isVisible, isEnabled: isEnabled) { context in
      try action(context)
    }
  }
}
