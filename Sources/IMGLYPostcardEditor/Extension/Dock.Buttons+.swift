import IMGLYCore
import IMGLYEngine
import SwiftUI

public extension Dock.Buttons.ID {
  /// The id of the ``IMGLYEditor/Buttons/designColors(action:title:icon:isEnabled:isVisible:)`` button.
  static var designColors: EditorComponentID { "ly.img.component.dock.button.postcard.designColors" }
  /// The id of the ``IMGLYEditor/Buttons/greetingColors(action:title:icon:isEnabled:isVisible:)`` button.
  static var greetingColors: EditorComponentID { "ly.img.component.dock.button.postcard.namedColors" }
  /// The id of the ``IMGLYEditor/Buttons/greetingFont(action:title:icon:isEnabled:isVisible:)`` button.
  static var greetingFont: EditorComponentID { "ly.img.component.dock.button.postcard.greetingFont" }
  /// The id of the ``IMGLYEditor/Buttons/greetingSize(action:title:icon:isEnabled:isVisible:)`` button.
  static var greetingSize: EditorComponentID { "ly.img.component.dock.button.postcard.greetingSize" }
}

public extension Dock.Buttons {
  /// Creates a ``Dock/Button`` that opens the selection colors sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``Postcard/SheetType/designColors(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_colors` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `View`
  /// ``Postcard/Icon/SelectionColors``
  /// is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if on the first page.
  /// - Returns: The created button.
  static func designColors(
    action: @escaping Dock.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(type: Postcard.SheetType.designColors()))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_colors"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Postcard.Icon.SelectionColors() },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.scene.getPages().first == $0.engine.scene.getCurrentPage()
    },
  ) -> some Dock.Item {
    Dock.Button(id: ID.designColors, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the color sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``Postcard/SheetType/greetingColors(style:id:colorPalette:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_colors` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `View` ``Postcard/Icon/Color``
  /// is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if on the last page.
  /// - Returns: The created button.
  static func greetingColors(
    action: @escaping Dock.Context.To<Void> = {
      guard let id = $0.engine.block.find(byName: "Greeting").first else { return }
      $0.eventHandler.send(.openSheet(type: Postcard.SheetType.greetingColors(id: id, colorPalette: [
        .init("Governor Bay", .imgly.hex("#263BAA")!),
        .init("Resolution Blue", .imgly.hex("#002094")!),
        .init("Stratos", .imgly.hex("#001346")!),
        .init("Blue Charcoal", .imgly.hex("#000514")!),
        .init("Black", .imgly.hex("#000000")!),
        .init("Dove Gray", .imgly.hex("#696969")!),
        .init("Dusty Gray", .imgly.hex("#999999")!),
      ])))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_colors"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = {
      let id = $0.engine.block.find(byName: "Greeting").first
      return Postcard.Icon.Color(id: id)
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.scene.getPages().last == $0.engine.scene.getCurrentPage()
    },
  ) -> some Dock.Item {
    Dock.Button(id: ID.greetingColors, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the font sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``Postcard/SheetType/greetingFont(style:id:fontFamilies:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_font` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `View` ``Postcard/Icon/Font``
  /// is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if on the last page.
  /// - Returns: The created button.
  static func greetingFont(
    action: @escaping Dock.Context.To<Void> = {
      guard let id = $0.engine.block.find(byName: "Greeting").first else { return }
      $0.eventHandler.send(.openSheet(type: Postcard.SheetType.greetingFont(id: id, fontFamilies: [
        "Caveat", "Amatic SC", "Courier Prime", "Archivo", "Roboto", "Parisienne",
      ])))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_font"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = {
      let id = $0.engine.block.find(byName: "Greeting").first
      return Postcard.Icon.Font(id: id)
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.scene.getPages().last == $0.engine.scene.getCurrentPage()
    },
  ) -> some Dock.Item {
    Dock.Button(id: ID.greetingFont, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the font size sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``Postcard/SheetType/greetingSize(style:id:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_size` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `View` ``Postcard/Icon/FontSize``
  /// is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if on the last page.
  /// - Returns: The created button.
  static func greetingSize(
    action: @escaping Dock.Context.To<Void> = {
      guard let id = $0.engine.block.find(byName: "Greeting").first else { return }
      $0.eventHandler.send(.openSheet(type: Postcard.SheetType.greetingSize(id: id)))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_size"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { context in
      let id = context.engine.block.find(byName: "Greeting").first
      return Postcard.Icon.FontSize(id: id)
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.scene.getPages().last == $0.engine.scene.getCurrentPage()
    },
  ) -> some Dock.Item {
    Dock.Button(id: ID.greetingSize, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }
}
