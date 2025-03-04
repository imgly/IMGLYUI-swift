import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

public extension InspectorBar {
  /// A namespace for inspector bar buttons.
  enum Buttons {}
}

public extension InspectorBar.Buttons {
  /// A namespace for inspector bar button IDs.
  enum ID {}
}

public extension InspectorBar.Buttons.ID {
  /// The id of the ``InspectorBar/Buttons/editVoiceover(action:title:icon:isEnabled:isVisible:)`` button.
  static var editVoiceover: EditorComponentID { "ly.img.component.inspectorBar.button.editVoiceover" }
  /// The id of the ``InspectorBar/Buttons/reorder(action:title:icon:isEnabled:isVisible:)`` button.
  static var reorder: EditorComponentID { "ly.img.component.inspectorBar.button.reorder" }
  /// The id of the ``InspectorBar/Buttons/adjustments(action:title:icon:isEnabled:isVisible:)`` button.
  static var adjustments: EditorComponentID { "ly.img.component.inspectorBar.button.adjustments" }
  /// The id of the ``InspectorBar/Buttons/filter(action:title:icon:isEnabled:isVisible:)`` button.
  static var filter: EditorComponentID { "ly.img.component.inspectorBar.button.filter" }
  /// The id of the ``InspectorBar/Buttons/effect(action:title:icon:isEnabled:isVisible:)`` button.
  static var effect: EditorComponentID { "ly.img.component.inspectorBar.button.effect" }
  /// The id of the ``InspectorBar/Buttons/blur(action:title:icon:isEnabled:isVisible:)`` button.
  static var blur: EditorComponentID { "ly.img.component.inspectorBar.button.blur" }
  /// The id of the ``InspectorBar/Buttons/volume(action:title:icon:isEnabled:isVisible:)`` button.
  static var volume: EditorComponentID { "ly.img.component.inspectorBar.button.volume" }
  /// The id of the ``InspectorBar/Buttons/crop(action:title:icon:isEnabled:isVisible:)`` button.
  static var crop: EditorComponentID { "ly.img.component.inspectorBar.button.crop" }
  /// The id of the ``InspectorBar/Buttons/duplicate(action:title:icon:isEnabled:isVisible:)`` button.
  static var duplicate: EditorComponentID { "ly.img.component.inspectorBar.button.duplicate" }
  /// The id of the ``InspectorBar/Buttons/layer(action:title:icon:isEnabled:isVisible:)`` button.
  static var layer: EditorComponentID { "ly.img.component.inspectorBar.button.layer" }
  /// The id of the ``InspectorBar/Buttons/split(action:title:icon:isEnabled:isVisible:)`` button.
  static var split: EditorComponentID { "ly.img.component.inspectorBar.button.split" }
  /// The id of the ``InspectorBar/Buttons/fillStroke(action:title:icon:isEnabled:isVisible:)`` button.
  static var fillStroke: EditorComponentID { "ly.img.component.inspectorBar.button.fillStroke" }
  /// The id of the ``InspectorBar/Buttons/moveAsClip(action:title:icon:isEnabled:isVisible:)`` button.
  static var moveAsClip: EditorComponentID { "ly.img.component.inspectorBar.button.moveAsClip" }
  /// The id of the ``InspectorBar/Buttons/moveAsOverlay(action:title:icon:isEnabled:isVisible:)`` button.
  static var moveAsOverlay: EditorComponentID { "ly.img.component.inspectorBar.button.moveAsOverlay" }
  /// The id of the ``InspectorBar/Buttons/replace(action:title:icon:isEnabled:isVisible:)`` button
  static var replace: EditorComponentID { "ly.img.component.inspectorBar.button.replace" }
  /// The id of the ``InspectorBar/Buttons/enterGroup(action:title:icon:isEnabled:isVisible:)`` button.
  static var enterGroup: EditorComponentID { "ly.img.component.inspectorBar.button.enterGroup" }
  /// The id of the ``InspectorBar/Buttons/selectGroup(action:title:icon:isEnabled:isVisible:)`` button.
  static var selectGroup: EditorComponentID { "ly.img.component.inspectorBar.button.selectGroup" }
  /// The id of the ``InspectorBar/Buttons/delete(action:title:icon:isEnabled:isVisible:)`` button.
  static var delete: EditorComponentID { "ly.img.component.inspectorBar.button.delete" }
  /// The id of the ``InspectorBar/Buttons/editText(action:title:icon:isEnabled:isVisible:)`` button.
  static var editText: EditorComponentID { "ly.img.component.inspectorBar.button.editText" }
  /// The id of the ``InspectorBar/Buttons/formatText(action:title:icon:isEnabled:isVisible:)`` button.
  static var formatText: EditorComponentID { "ly.img.component.inspectorBar.button.formatText" }
  /// The id of the ``InspectorBar/Buttons/shape(action:title:icon:isEnabled:isVisible:)`` button.
  static var shape: EditorComponentID { "ly.img.component.inspectorBar.button.shape" }
}

@MainActor
public extension InspectorBar.Buttons {
  /// Creates a ``InspectorBar/Button`` that opens the voiceover sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button.  By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/voiceover(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Edit" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/editVoiceover``  is
  /// used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block type is
  /// `DesignBlockType.audio` and its kind is `"voiceover"`.
  /// - Returns: The created button.
  static func editVoiceover(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(type: .voiceover())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Edit") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.editVoiceover },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      $0.selection.type == .audio &&
        $0.selection.kind == "voiceover"
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.editVoiceover, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the reorder sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/reorder(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Reorder" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/reorder``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block is the
  /// background track with more than one child.
  /// - Returns: The created button.
  static func reorder(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(type: .reorder())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Reorder") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.reorder },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = { context in
      @MainActor func isBackgroundTrack(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try context.engine.block.getType(id) == DesignBlockType.track.rawValue &&
            context.engine.block.isAlwaysOnBottom(id)
        } else {
          false
        }
      }
      return if let backgroundTrack = context.selection.parentBlock,
                try context.engine.block.getChildren(backgroundTrack).count > 1,
                try isBackgroundTrack(backgroundTrack) {
        true
      } else {
        false
      }
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.reorder, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the adjustments sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/adjustments(style:id:)`` for the selected design block.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Adjustments" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/adjustments``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block has a
  /// fill type `FillType.video` or `.image`, its kind is not `"sticker"`, and its engine scope
  /// `"appearance/adjustments"` is allowed.
  /// - Returns: The created button.
  static func adjustments(
    action: @escaping InspectorBar.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(type: .adjustments(id: $0.selection.block)))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Adjustments") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.adjustments },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try [.video, .image].contains($0.selection.fillType) &&
        $0.selection.kind != "sticker" &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "appearance/adjustments")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.adjustments, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the filter sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/filter(style:id:)`` for the selected design block.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Filter" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/filter``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block has a
  /// fill type `FillType.video` or `.image`, its kind is not `"sticker"`, and its engine scope `"appearance/filter"` is
  /// allowed.
  /// - Returns: The created button.
  static func filter(
    action: @escaping InspectorBar.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(type: .filter(id: $0.selection.block)))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Filter") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.filter },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try [.video, .image].contains($0.selection.fillType) &&
        $0.selection.kind != "sticker" &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "appearance/filter")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.filter, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the effect sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/effect(style:id:)`` for the selected design block.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Effect" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/effect``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block has a
  /// fill type `FillType.video` or `.image`, its kind is not `"sticker"`, and its engine scope `"appearance/effect"` is
  /// allowed.
  /// - Returns: The created button.
  static func effect(
    action: @escaping InspectorBar.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(type: .effect(id: $0.selection.block)))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Effect") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.effect },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try [.video, .image].contains($0.selection.fillType) &&
        $0.selection.kind != "sticker" &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "appearance/effect")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.effect, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the blur sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/blur(style:id:)`` for the selected design block.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Blur" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/blur``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block has a
  /// fill type `FillType.video` or `.image`, its kind is not `"sticker"`, and its engine scope `"appearance/blur"` is
  /// allowed.
  /// - Returns: The created button.
  static func blur(
    action: @escaping InspectorBar.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(type: .blur(id: $0.selection.block)))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Blur") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.blur },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try [.video, .image].contains($0.selection.fillType) &&
        $0.selection.kind != "sticker" &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "appearance/blur")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.blur, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the volume sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/volume(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Volume" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/volume``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block type is
  /// `DesignBlockType.audio` or its fill type is `FillType.video`, and its engine scope `"fill/change"` is allowed.
  /// - Returns: The created button.
  static func volume(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(type: .volume())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Volume") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.volume },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try ($0.selection.type == .audio || $0.selection.fillType == .video) &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "fill/change")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.volume, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the crop sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/crop(style:id:)`` for the selected design block.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Crop" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/crop``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block has a
  /// fill type `FillType.video` or `.image`, its kind is not `"sticker"`, and its engine scope `"layer/crop"` is
  /// allowed.
  /// - Returns: The created button.
  static func crop(
    action: @escaping InspectorBar.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(type: .crop(id: $0.selection.block)))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Crop") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.crop },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try [.video, .image].contains($0.selection.fillType) &&
        $0.selection.kind != "sticker" &&
        $0.engine.block.supportsCrop($0.selection.block) &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "layer/crop")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.crop, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that duplicates the selected design block.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/duplicateSelection`` event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Duplicate" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/duplicate``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block type is
  /// not `DesignBlockType.page`, its kind is not `"voiceover"`, it is not grouped, and its engine scope
  /// `"lifecycle/duplicate"` is allowed.
  /// - Returns: The created button.
  static func duplicate(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.duplicateSelection) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Duplicate") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.duplicate },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = { context in
      @MainActor func isGrouped(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try context.engine.block.getType(id) == DesignBlockType.group.rawValue
        } else {
          false
        }
      }
      return try context.selection.type != .page &&
        context.selection.kind != "voiceover" &&
        !isGrouped(context.selection.parentBlock) &&
        context.engine.block.isAllowedByScope(context.selection.block, key: "lifecycle/duplicate")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.duplicate, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the layer sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/layer(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Layer" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/layer``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block type is
  /// not `DesignBlockType.page`, its kind is not `"voiceover"`, and its engine scope `"layer/blendMode"`,
  /// `"layer/opacity"`, `"editor/add"`, `"lifecycle/duplicate"`, or `"lifecycle/destroy"` is allowed.
  /// - Returns: The created button.
  static func layer(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(type: .layer())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Layer") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.layer },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = { context in
      @MainActor func isBackgroundTrack(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try context.engine.block.getType(id) == DesignBlockType.track.rawValue &&
            context.engine.block.isAlwaysOnBottom(id)
        } else {
          false
        }
      }
      @MainActor func isGrouped(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try context.engine.block.getType(id) == DesignBlockType.group.rawValue
        } else {
          false
        }
      }
      @MainActor func isMoveAllowed() throws -> Bool {
        try context.engine.block.isAllowedByScope(context.selection.block, key: "editor/add") &&
          !isGrouped(context.selection.parentBlock) &&
          !isBackgroundTrack(context.selection.parentBlock)
      }
      @MainActor func isDuplicateAllowed() throws -> Bool {
        try context.engine.block.isAllowedByScope(context.selection.block, key: "lifecycle/duplicate") &&
          !isGrouped(context.selection.parentBlock)
      }
      @MainActor func isDeleteAllowed() throws -> Bool {
        try context.engine.block.isAllowedByScope(context.selection.block, key: "lifecycle/destroy") &&
          !isGrouped(context.selection.parentBlock)
      }
      return try ![.page, .audio].contains(context.selection.type) &&
        context.selection.kind != "voiceover" && (
          context.engine.block.isAllowedByScope(context.selection.block, key: "layer/blendMode") ||
            context.engine.block.isAllowedByScope(context.selection.block, key: "layer/opacity") ||
            isMoveAllowed() ||
            isDeleteAllowed() ||
            isDuplicateAllowed()
        )
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.layer, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that splits the selected design block.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/splitSelection``
  /// event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Split" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/split``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the scene mode is
  /// `SceneMode.video`, the selected design block kind is not `"voiceover"`, and its engine scope
  /// `"lifecycle/duplicate"` is allowed.
  /// - Returns: The created button.
  static func split(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.splitSelection) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Split") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.split },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try $0.engine.scene.getMode() == .video &&
        $0.selection.kind != "voiceover" &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "lifecycle/duplicate")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.split, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the fill and stroke sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/fillStroke(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Fill & Stroke", "Fill", or
  /// "Stroke"  is used depending on the fill type and allowed engine scopes for the selected design block.
  ///   - icon: The icon view which is used to label the button. By default, the `FillStrokeIcon` is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block kind is
  /// not `"sticker"`, its fill type is `FillType.color`, `.linearGradient`, or `.none`, and its engine scope
  /// `"fill/change"` or `"stroke/change"` is allowed.
  /// - Returns: The created button.
  static func fillStroke(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(type: .fillStroke())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = {
      let showFill = try [.none, .color, .linearGradient].contains($0.selection.fillType) &&
        $0.engine.block.supportsFill($0.selection.block) &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "fill/change")
      let showStroke = try $0.engine.block.supportsStroke($0.selection.block) &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "stroke/change")
      var title = [String]()
      if showFill {
        title.append("Fill")
      }
      if showStroke {
        title.append("Stroke")
      }
      return Text(LocalizedStringKey(title.joined(separator: " & ")))
    },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = {
      FillStrokeIcon(id: $0.selection.block)
    },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      let showFill = try [.none, .color, .linearGradient].contains($0.selection.fillType) &&
        $0.engine.block.supportsFill($0.selection.block) &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "fill/change")
      let showStroke = try $0.engine.block.supportsStroke($0.selection.block) &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "stroke/change")
      return $0.selection.kind != "sticker" && (showFill || showStroke)
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.fillStroke, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that moves the selected design block into the background track as clip.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/moveSelectionAsClip`` event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` "As Clip" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/moveAsClip``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the scene mode is
  /// `SceneMode.video`, the selected design block type is not `DesignBlockType.audio`, and its parent is not the
  /// background track.
  /// - Returns: The created button.
  static func moveAsClip(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.moveSelectionAsClip) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("As Clip") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.moveAsClip },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = { context in
      @MainActor func isBackgroundTrack(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try context.engine.block.getType(id) == DesignBlockType.track.rawValue &&
            context.engine.block.isAlwaysOnBottom(id)
        } else {
          false
        }
      }
      return try context.engine.scene.getMode() == .video &&
        context.selection.type != .audio &&
        !isBackgroundTrack(context.selection.parentBlock)
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.moveAsClip, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that moves the selected design block from the background track to an overlay.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/moveSelectionAsOverlay`` event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` "As Overlay" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/moveAsOverlay``  is
  /// used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the scene mode is
  /// `SceneMode.video`, the selected design block type is not `DesignBlockType.audio`, and its parent is the background
  /// track.
  /// - Returns: The created button.
  static func moveAsOverlay(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.moveSelectionAsOverlay) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("As Overlay") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.moveAsOverlay },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = { context in
      @MainActor func isBackgroundTrack(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try context.engine.block.getType(id) == DesignBlockType.track.rawValue &&
            context.engine.block.isAlwaysOnBottom(id)
        } else {
          false
        }
      }
      return try context.engine.scene.getMode() == .video &&
        context.selection.type != .audio &&
        isBackgroundTrack(context.selection.parentBlock)
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.moveAsOverlay, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the replace sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/libraryReplace(style:content:)`` where the library content is picked
  /// from the ``AssetLibrary`` based on the `DesignBlockType`, `FillType`, and kind of the selected design block.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Replace" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/replace``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block type is
  /// `DesignBlockType.audio` or `.graphic`, its fill type is `FillType.video` or `.image`, and its engine scope
  /// `"fill/change"` is allowed.
  /// - Returns: The created button.
  static func replace(
    action: @escaping InspectorBar.Context.To<Void> = { context in
      let libraryTab = try {
        switch context.selection.type {
        case .audio: context.assetLibrary.audioTab
        case .graphic:
          switch context.selection.fillType {
          case .video: context.assetLibrary.videosTab
          case .image:
            if context.selection.kind == "sticker" {
              context.assetLibrary.stickersTab
            } else {
              context.assetLibrary.imagesTab
            }
          default:
            throw EditorError(
              "Unsupported fillType \(context.selection.fillType?.rawValue ?? "") for replace inspector bar button."
            )
          }
        default:
          throw EditorError(
            "Unsupported type \(context.selection.type?.rawValue ?? "") for replace inspector bar button."
          )
        }
      }()
      context.eventHandler.send(.openSheet(type: .libraryReplace { libraryTab }))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Replace") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.replace },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try (
        $0.selection.type == .audio || (
          $0.selection.type == .graphic &&
            [.image, .video].contains($0.selection.fillType)
        )
      ) && $0.engine.block.isAllowedByScope($0.selection.block, key: "fill/change")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.replace, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that changes selection from the selected group design block to a design block
  /// within that group.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/enterGroupForSelection`` event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Enter Group" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/enterGroup``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block type is
  /// `DesignBlockType.group`.
  /// - Returns: The created button.
  static func enterGroup(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.enterGroupForSelection) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Enter Group") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.enterGroup },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      $0.selection.type == .group
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.enterGroup, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that selects the group design block containing the selected design block.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/selectGroupForSelection`` event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Select Group" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/selectGroup``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block is part
  /// of a group.
  /// - Returns: The created button.
  static func selectGroup(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.selectGroupForSelection) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Select Group") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.selectGroup },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = { context in
      @MainActor func isGrouped(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try context.engine.block.getType(id) == DesignBlockType.group.rawValue
        } else {
          false
        }
      }
      return try isGrouped(context.selection.parentBlock)
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.selectGroup, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that deletes the selected design block.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/deleteSelection``
  /// event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Delete" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/delete``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block type is
  /// not `DesignBlockType.page`, it is not grouped, and its engine scope `"lifecycle/destroy"` is allowed
  /// - Returns: The created button.
  static func delete(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.deleteSelection) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Delete").foregroundColor(.red) },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.delete.foregroundColor(.red) },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = { context in
      @MainActor func isGrouped(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try context.engine.block.getType(id) == DesignBlockType.group.rawValue
        } else {
          false
        }
      }
      @MainActor func isDeleteAllowed() throws -> Bool {
        try context.engine.block.isAllowedByScope(context.selection.block, key: "lifecycle/destroy") &&
          !isGrouped(context.selection.parentBlock)
      }
      return try context.selection.type != .page &&
        isDeleteAllowed()
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.delete, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that enters the text edit mode for the selected design block.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/enterTextEditModeForSelection`` event is invoked.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Edit" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/editText``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block type is
  /// `DesignBlockType.text` and its engine scope `"text/edit"` is allowed.
  /// - Returns: The created button.
  static func editText(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.enterTextEditModeForSelection) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Edit") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.editText },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try $0.selection.type == .text &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "text/edit")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.editText, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the format text sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/formatText(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Format" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/formatText``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block type is
  /// `DesignBlockType.text` and its engine scope `"text/character"` is allowed.
  /// - Returns: The created button.
  static func formatText(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(type: .formatText())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Format") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.formatText },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try $0.selection.type == .text &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "text/character")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.formatText, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``InspectorBar/Button`` that opens the shape sheet.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/openSheet(type:)``
  /// event is invoked with sheet type ``SheetType/shape(style:)``.
  ///   - title: The title view which is used to label the button. By default, the `Text` "Shape" is used.
  ///   - icon: The icon view which is used to label the button. By default, the `Image` ``IMGLY/shape``  is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block fill type
  /// is not `FillType.image` or its kind is not `"sticker"`, its engine scope `"shape/change"` is allowed, and its
  /// shape type is `ShapeType.line`, `.star`, `.polygon`, or `.rect`.
  /// - Returns: The created button.
  static func shape(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(type: .shape())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Shape") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.shape },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try ($0.selection.fillType != .image || $0.selection.kind != "sticker") &&
        $0.engine.block.isAllowedByScope($0.selection.block, key: "shape/change") &&
        $0.engine.block.supportsShape($0.selection.block) &&
        [.line, .star, .polygon, .rect].contains(
          ShapeType(rawValue: $0.engine.block.getType($0.engine.block.getShape($0.selection.block)))
        )
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.shape, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }
}
