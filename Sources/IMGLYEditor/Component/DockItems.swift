import IMGLYEngine
import SwiftUI

public extension Dock {
  /// A namespace for dock buttons.
  enum Buttons {}
}

public extension Dock.Buttons {
  /// A namespace for dock button IDs.
  enum ID {}
}

public extension Dock.Buttons.ID {
  /// The id of the ``Dock/Buttons/elementsLibrary(action:title:icon:isEnabled:isVisible:)`` button.
  static var elementsLibrary: EditorComponentID { "ly.img.component.dock.button.elementsLibrary" }
  /// The id of the ``Dock/Buttons/audioLibrary(action:title:icon:isEnabled:isVisible:)`` button.
  static var audioLibrary: EditorComponentID { "ly.img.component.dock.button.audioLibrary" }
  /// The id of the ``Dock/Buttons/imagesLibrary(action:title:icon:isEnabled:isVisible:)`` button.
  static var imagesLibrary: EditorComponentID { "ly.img.component.dock.button.imagesLibrary" }
  /// The id of the ``Dock/Buttons/textLibrary(action:title:icon:isEnabled:isVisible:)`` button.
  static var textLibrary: EditorComponentID { "ly.img.component.dock.button.textLibrary" }
  /// The id of the ``Dock/Buttons/shapesLibrary(action:title:icon:isEnabled:isVisible:)`` button.
  static var shapesLibrary: EditorComponentID { "ly.img.component.dock.button.shapesLibrary" }
  /// The id of the ``Dock/Buttons/stickersLibrary(action:title:icon:isEnabled:isVisible:)`` button.
  static var stickersLibrary: EditorComponentID { "ly.img.component.dock.button.stickersLibrary" }

  /// The id of the ``Dock/Buttons/overlaysLibrary(action:title:icon:isEnabled:isVisible:)`` button.
  static var overlaysLibrary: EditorComponentID { "ly.img.component.dock.button.overlaysLibrary" }
  /// The id of the ``Dock/Buttons/stickersAndShapesLibrary(action:title:icon:isEnabled:isVisible:)`` button.
  static var stickersAndShapesLibrary: EditorComponentID { "ly.img.component.dock.button.stickersAndShapesLibrary" }

  /// The id of the ``Dock/Buttons/photoRoll(action:title:icon:isEnabled:isVisible:)`` button.
  static var photoRoll: EditorComponentID { "ly.img.component.dock.button.photoRoll" }
  /// The id of the ``Dock/Buttons/systemPhotoRoll(action:title:icon:isEnabled:isVisible:)`` button.
  @available(*, deprecated, message: """
  Deprecated in v1.66.0. Please see the changelog for migration details:
  https://img.ly/docs/cesdk/changelog/v1-66-0/
  """)
  static var systemPhotoRoll: EditorComponentID { "ly.img.component.dock.button.systemPhotoRoll" }
  /// The id of the ``Dock/Buttons/imglyPhotoRoll(action:title:icon:isEnabled:isVisible:)`` button.
  @available(*, deprecated, message: """
  Deprecated in v1.66.0. Please see the changelog for migration details:
  https://img.ly/docs/cesdk/changelog/v1-66-0/
  """)
  static var imglyPhotoRoll: EditorComponentID { "ly.img.component.dock.button.imglyPhotoRoll" }
  /// The id of the ``Dock/Buttons/systemCamera(action:title:icon:isEnabled:isVisible:)`` button.
  static var systemCamera: EditorComponentID { "ly.img.component.dock.button.systemCamera" }
  /// The id of the ``Dock/Buttons/imglyCamera(action:title:icon:isEnabled:isVisible:)`` button.
  static var imglyCamera: EditorComponentID { "ly.img.component.dock.button.imglyCamera" }
  /// The id of the ``Dock/Buttons/voiceover(action:title:icon:isEnabled:isVisible:)`` button.
  static var voiceover: EditorComponentID { "ly.img.component.dock.button.voiceover" }

  /// The id of the ``Dock/Buttons/reorder(action:title:icon:isEnabled:isVisible:)`` button.
  static var reorder: EditorComponentID { "ly.img.component.dock.button.reorder" }
  /// The id of the ``Dock/Buttons/adjustments(action:title:icon:isEnabled:isVisible:)`` button.
  static var adjustments: EditorComponentID { "ly.img.component.dock.button.adjustments" }
  /// The id of the ``Dock/Buttons/filter(action:title:icon:isEnabled:isVisible:)`` button.
  static var filter: EditorComponentID { "ly.img.component.dock.button.filter" }
  /// The id of the ``Dock/Buttons/effect(action:title:icon:isEnabled:isVisible:)`` button.
  static var effect: EditorComponentID { "ly.img.component.dock.button.effect" }
  /// The id of the ``Dock/Buttons/blur(action:title:icon:isEnabled:isVisible:)`` button.
  static var blur: EditorComponentID { "ly.img.component.dock.button.blur" }
  /// The id of the ``Dock/Buttons/crop(action:title:icon:isEnabled:isVisible:)`` button.
  static var crop: EditorComponentID { "ly.img.component.dock.button.crop" }
  /// The id of the ``Dock/Buttons/resize(action:title:icon:isEnabled:isVisible:)`` button.
  static var resize: EditorComponentID { "ly.img.component.dock.button.resize" }
  /// The id of the ``Dock/Buttons/assetLibrary(action:title:icon:isEnabled:isVisible:)`` button.
  static var assetLibrary: EditorComponentID { "ly.img.component.dock.button.assetLibrary" }
}

@MainActor
public extension Dock.Buttons {
  /// Creates a ``Dock/Button`` that opens the elements library sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/libraryAdd(style:content:)`` and ``AssetLibrary/elementsTab`` content
  /// is displayed on the sheet.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_elements` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addElement``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func elementsLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(type: .libraryAdd { context.assetLibrary.elementsTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_elements"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addElement },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.elementsLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the audio library sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/libraryAdd(style:content:)`` and ``AssetLibrary/audioTab`` content is
  /// displayed on the sheet.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_audio` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addAudio``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func audioLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(type: .libraryAdd { context.assetLibrary.audioTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_audio"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addAudio },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.audioLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the images library sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/libraryAdd(style:content:)`` and ``AssetLibrary/imagesTab`` content
  /// is displayed on the sheet.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_images` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addImage``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func imagesLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(type: .libraryAdd { context.assetLibrary.imagesTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_images"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addImage },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.imagesLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the text library sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/libraryAdd(style:content:)`` and ``AssetLibrary/textTab`` content is
  /// displayed on the sheet.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_text` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addText``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func textLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(type: .libraryAdd(style: .addAsset(detent: .imgly.medium)) {
        context.assetLibrary.textTab
      }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_text"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addText },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.textLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the shapes library sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/libraryAdd(style:content:)`` and ``AssetLibrary/shapesTab`` content
  /// is displayed on the
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_shapes` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addShape``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func shapesLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(type: .libraryAdd { context.assetLibrary.shapesTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_shapes"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addShape },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.shapesLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the stickers library sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/libraryAdd(style:content:)`` and ``AssetLibrary/stickersTab`` content
  /// is displayed on the sheet.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_stickers` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addSticker``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func stickersLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(type: .libraryAdd { context.assetLibrary.stickersTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_stickers"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addSticker },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.stickersLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the overlays library sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/libraryAdd(style:content:)`` and ``AssetLibrary/overlaysTab`` content
  /// is displayed on the sheet.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_overlays` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addVideo``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func overlaysLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(type: .libraryAdd { context.assetLibrary.overlaysTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_overlays"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addVideo },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.overlaysLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the stickers and shapes library sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/libraryAdd(style:content:)`` and
  /// ``AssetLibrary/stickersAndShapesTab`` content is displayed on the sheet.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_stickers` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addSticker``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func stickersAndShapesLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(type: .libraryAdd { context.assetLibrary.stickersAndShapesTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _
      in Text(.imgly.localized("ly_img_editor_dock_button_stickers"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addSticker },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.stickersAndShapesLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the photo roll.
  ///
  /// By default, this button opens a system photos picker (no permissions required).
  /// To enable full photo library access, use ``PhotoRollAssetSource`` with `mode: .fullLibraryAccess`
  /// in your ``OnCreate`` callback.
  ///
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  ///   invokes ``EditorEvent/addFromPhotoRoll`` which internally determines behavior based on the
  ///   ``PhotoRollAssetSourceMode`` used when creating the ``PhotoRollAssetSource``.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  ///   `ly_img_editor_dock_button_photo_roll` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image`
  ///   ``IMGLY/addPhotoRollForeground``  or ``IMGLY/addPhotoRollBackground`` is used depending on the scene mode.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func photoRoll(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.addFromPhotoRoll) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_photo_roll"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { context in
      let isVideoScene = try context.engine.scene.getMode() == .video
      return isVideoScene ? Image.imgly.addPhotoRollBackground : Image.imgly.addPhotoRollForeground
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.photoRoll, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the system photo roll.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/addFromSystemPhotoRoll(to:)`` event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_photo_roll` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image`
  /// ``IMGLY/addPhotoRollForeground``  or ``IMGLY/addPhotoRollBackground`` is used depending on the scene mode.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  @available(*, deprecated, message: """
  Deprecated in v1.66.0. Please see the changelog for migration details:
  https://img.ly/docs/cesdk/changelog/v1-66-0/
  """)
  static func systemPhotoRoll(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.addFromSystemPhotoRoll()) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_photo_roll"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { context in
      let isVideoScene = try context.engine.scene.getMode() == .video
      return isVideoScene ? Image.imgly.addPhotoRollBackground : Image.imgly.addPhotoRollForeground
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.systemPhotoRoll, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the photo roll library sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/addFromIMGLYPhotoRoll``
  /// event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_photo_roll` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image`
  /// ``IMGLY/addPhotoRollForeground``  or ``IMGLY/addPhotoRollBackground`` is used depending on the scene mode.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  @available(*, deprecated, message: """
  Deprecated in v1.66.0. Please see the changelog for migration details:
  https://img.ly/docs/cesdk/changelog/v1-66-0/
  """)
  static func imglyPhotoRoll(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.addFromIMGLYPhotoRoll) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_photo_roll"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { context in
      let isVideoScene = try context.engine.scene.getMode() == .video
      return isVideoScene ? Image.imgly.addPhotoRollBackground : Image.imgly.addPhotoRollForeground
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.imglyPhotoRoll, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the system camera.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/addFromSystemCamera(to:)`` event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_camera` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addCameraForeground``
  /// or ``IMGLY/addCameraBackground`` is used depending on the scene mode.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func systemCamera(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.addFromSystemCamera()) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_camera"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { context in
      let isVideoScene = try context.engine.scene.getMode() == .video
      return isVideoScene ? Image.imgly.addCameraBackground : Image.imgly.addCameraForeground
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.systemCamera, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the IMGLY camera.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/addFromIMGLYCamera(to:)`` event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_camera` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addCameraForeground``
  /// or ``IMGLY/addCameraBackground`` is used depending on the scene mode.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func imglyCamera(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.addFromIMGLYCamera()) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_camera"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { context in
      let isVideoScene = try context.engine.scene.getMode() == .video
      return isVideoScene ? Image.imgly.addCameraBackground : Image.imgly.addCameraForeground
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.imglyCamera, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the voiceover sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/voiceover(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_voiceover` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addVoiceover``  is
  /// used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func voiceover(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.openSheet(type: .voiceover())) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_voiceover"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addVoiceover },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.voiceover, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the reorder sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/reorder(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_reorder` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/reorder``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if there is more than one child in the
  /// background track.
  /// - Returns: The created button.
  static func reorder(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.openSheet(type: .reorder())) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_reorder"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.reorder },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { context in
      let backgroundTrack = try context.engine.block.find(byType: .track).filter {
        try context.engine.block.isPageDurationSource($0)
      }.first
      guard let backgroundTrack else {
        return false
      }
      return try context.engine.block.getChildren(backgroundTrack).count > 1
    },
  ) -> some Dock.Item {
    Dock.Button(id: ID.reorder, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the adjustments sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/adjustments(style:id:)`` for the current page.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_adjustments` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/adjustments``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the engine scope
  /// `"appearance/adjustments"` is allowed for the current page.
  /// - Returns: The created button.
  static func adjustments(
    action: @escaping Dock.Context.To<Void> = {
      try $0.eventHandler.send(.openSheet(type: .adjustments(id: nonNil($0.engine.scene.getCurrentPage()))))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_adjustments"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.adjustments },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope(nonNil($0.engine.scene.getCurrentPage()), key: "appearance/adjustments")
    },
  ) -> some Dock.Item {
    Dock.Button(id: ID.adjustments, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the filter sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/filter(style:id:)`` for the current page.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_filter` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/filter``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the engine scope
  /// `"appearance/filter"` is allowed for the current page.
  /// - Returns: The created button.
  static func filter(
    action: @escaping Dock.Context.To<Void> = {
      try $0.eventHandler.send(.openSheet(type: .filter(id: nonNil($0.engine.scene.getCurrentPage()))))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_filter"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.filter },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope(nonNil($0.engine.scene.getCurrentPage()), key: "appearance/filter")
    },
  ) -> some Dock.Item {
    Dock.Button(id: ID.filter, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the effect sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/effect(style:id:)`` for the current page.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_effect` is used
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/effect``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the engine scope
  /// `"appearance/effect"` is allowed for the current page.
  /// - Returns: The created button.
  static func effect(
    action: @escaping Dock.Context.To<Void> = {
      try $0.eventHandler.send(.openSheet(type: .effect(id: nonNil($0.engine.scene.getCurrentPage()))))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_effect"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.effect },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope(nonNil($0.engine.scene.getCurrentPage()), key: "appearance/effect")
    },
  ) -> some Dock.Item {
    Dock.Button(id: ID.effect, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the blur sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/blur(style:id:)`` for the current page.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_blur` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/blur``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the engine scope
  /// `"appearance/blur"` is allowed for the current page.
  /// - Returns: The created button.
  static func blur(
    action: @escaping Dock.Context.To<Void> = {
      try $0.eventHandler.send(.openSheet(type: .blur(id: nonNil($0.engine.scene.getCurrentPage()))))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_blur"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.blur },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope(nonNil($0.engine.scene.getCurrentPage()), key: "appearance/blur")
    },
  ) -> some Dock.Item {
    Dock.Button(id: ID.blur, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the crop sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/crop(style:id:assetSourceIDs:)`` for the current page.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_crop` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/crop``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the engine scope `"layer/crop"` is
  /// allowed for the current page.
  /// - Returns: The created button.
  static func crop(
    action: @escaping Dock.Context.To<Void> = {
      try $0.eventHandler.send(.openSheet(type: .crop(
        id: nonNil($0.engine.scene.getCurrentPage()),
        assetSourceIDs: [Engine.DefaultAssetSource.cropPresets.rawValue,
                         Engine.DefaultAssetSource.pagePresets.rawValue],
      )))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_crop"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.crop },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope(nonNil($0.engine.scene.getCurrentPage()), key: "layer/crop")
    },
  ) -> some Dock.Item {
    Dock.Button(id: ID.crop, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the resize sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/resize(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_resize` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/resize``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func resize(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.openSheet(type: .resize())) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_resize"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.resize },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
  ) -> some Dock.Item {
    Dock.Button(id: ID.resize, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``Dock/Button`` that opens the asset library sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/libraryAdd(style:content:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` with localization key
  /// `ly_img_editor_dock_button_library` is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/addAsset``  is
  /// used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  ///   - modifier: The ViewModifier to apply to the dock button. By default, the `EmptyModifier` is
  /// used.
  /// - Returns: The created button.
  static func assetLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(type: .libraryAdd { context.assetLibrary }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in
      Text(.imgly.localized("ly_img_editor_dock_button_library"))
    },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addAsset },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true },
    modifier: @escaping Dock.Context.To<some ViewModifier> = { _ in EmptyModifier() },
  ) -> some Dock.Item {
    Dock.Button(id: ID.assetLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible, modifier: modifier)
  }
}

public extension Dock.Buttons {
  /// A `ViewModifier` for the ``Dock/Buttons/assetLibrary(action:title:icon:isEnabled:isVisible:modifier:)``.
  struct AssetLibraryModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
      content
        .buttonStyle(.imgly.assetLibrary)
        .padding(.horizontal, 8)
    }
  }
}
