import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

public extension InspectorBar {
  enum Buttons {}
}

public extension InspectorBar.Buttons {
  enum ID {}
}

public extension InspectorBar.Buttons.ID {
  static var editVoiceover: EditorComponentID { "ly.img.component.inspectorBar.button.editVoiceover" }
  static var reorder: EditorComponentID { "ly.img.component.inspectorBar.button.reorder" }
  static var adjustments: EditorComponentID { "ly.img.component.inspectorBar.button.adjustments" }
  static var filter: EditorComponentID { "ly.img.component.inspectorBar.button.filter" }
  static var effect: EditorComponentID { "ly.img.component.inspectorBar.button.effect" }
  static var blur: EditorComponentID { "ly.img.component.inspectorBar.button.blur" }
  static var volume: EditorComponentID { "ly.img.component.inspectorBar.button.volume" }
  static var crop: EditorComponentID { "ly.img.component.inspectorBar.button.crop" }
  static var duplicate: EditorComponentID { "ly.img.component.inspectorBar.button.duplicate" }
  static var layer: EditorComponentID { "ly.img.component.inspectorBar.button.layer" }
  static var split: EditorComponentID { "ly.img.component.inspectorBar.button.split" }
  static var fillStroke: EditorComponentID { "ly.img.component.inspectorBar.button.fillStroke" }
  static var moveAsClip: EditorComponentID { "ly.img.component.inspectorBar.button.moveAsClip" }
  static var moveAsOverlay: EditorComponentID { "ly.img.component.inspectorBar.button.moveAsOverlay" }
  static var replace: EditorComponentID { "ly.img.component.inspectorBar.button.replace" }
  static var enterGroup: EditorComponentID { "ly.img.component.inspectorBar.button.enterGroup" }
  static var selectGroup: EditorComponentID { "ly.img.component.inspectorBar.button.selectGroup" }
  static var delete: EditorComponentID { "ly.img.component.inspectorBar.button.delete" }
  static var editText: EditorComponentID { "ly.img.component.inspectorBar.button.editText" }
  static var formatText: EditorComponentID { "ly.img.component.inspectorBar.button.formatText" }
  static var shape: EditorComponentID { "ly.img.component.inspectorBar.button.shape" }
}

@MainActor
public extension InspectorBar.Buttons {
  static func editVoiceover(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(.voiceover())) },
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

  static func reorder(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(.reorder())) },
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
      return if let backgroundTrack = context.selection.parent,
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

  static func adjustments(
    action: @escaping InspectorBar.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(.adjustments(id: $0.selection.id)))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Adjustments") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.adjustments },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try [.video, .image].contains($0.selection.fillType) &&
        $0.selection.kind != "sticker" &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "appearance/adjustments")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.adjustments, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func filter(
    action: @escaping InspectorBar.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(.filter(id: $0.selection.id)))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Filter") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.filter },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try [.video, .image].contains($0.selection.fillType) &&
        $0.selection.kind != "sticker" &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "appearance/filter")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.filter, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func effect(
    action: @escaping InspectorBar.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(.effect(id: $0.selection.id)))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Effect") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.effect },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try [.video, .image].contains($0.selection.fillType) &&
        $0.selection.kind != "sticker" &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "appearance/effect")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.effect, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func blur(
    action: @escaping InspectorBar.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(.blur(id: $0.selection.id)))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Blur") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.blur },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try [.video, .image].contains($0.selection.fillType) &&
        $0.selection.kind != "sticker" &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "appearance/blur")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.blur, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func volume(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(.volume())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Volume") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.volume },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try ($0.selection.type == .audio || $0.selection.fillType == .video) &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "fill/change")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.volume, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func crop(
    action: @escaping InspectorBar.Context.To<Void> = {
      $0.eventHandler.send(.openSheet(.crop(id: $0.selection.id)))
    },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Crop") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.crop },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try [.video, .image].contains($0.selection.fillType) &&
        $0.selection.kind != "sticker" &&
        $0.engine.block.supportsCrop($0.selection.id) &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "layer/crop")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.crop, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

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
        !isGrouped(context.selection.parent) &&
        context.engine.block.isAllowedByScope(context.selection.id, key: "lifecycle/duplicate")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.duplicate, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func layer(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(.layer())) },
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
        try context.engine.block.isAllowedByScope(context.selection.id, key: "editor/add") &&
          !isGrouped(context.selection.parent) &&
          !isBackgroundTrack(context.selection.parent)
      }
      @MainActor func isDuplicateAllowed() throws -> Bool {
        try context.engine.block.isAllowedByScope(context.selection.id, key: "lifecycle/duplicate") &&
          !isGrouped(context.selection.parent)
      }
      @MainActor func isDeleteAllowed() throws -> Bool {
        try context.engine.block.isAllowedByScope(context.selection.id, key: "lifecycle/destroy") &&
          !isGrouped(context.selection.parent)
      }
      return try ![.page, .audio].contains(context.selection.type) &&
        context.selection.kind != "voiceover" && (
          context.engine.block.isAllowedByScope(context.selection.id, key: "layer/blendMode") ||
            context.engine.block.isAllowedByScope(context.selection.id, key: "layer/opacity") ||
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

  static func split(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.splitSelection) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Split") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.split },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try $0.engine.scene.getMode() == .video &&
        $0.selection.kind != "voiceover" &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "lifecycle/duplicate")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.split, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func fillStroke(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(.fillStroke())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = {
      let showFill = try [.none, .color, .linearGradient].contains($0.selection.fillType) &&
        $0.engine.block.supportsFill($0.selection.id) &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "fill/change")
      let showStroke = try $0.engine.block.supportsStroke($0.selection.id) &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "stroke/change")
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
      FillStrokeIcon(id: $0.selection.id)
    },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      let showFill = try [.none, .color, .linearGradient].contains($0.selection.fillType) &&
        $0.engine.block.supportsFill($0.selection.id) &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "fill/change")
      let showStroke = try $0.engine.block.supportsStroke($0.selection.id) &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "stroke/change")
      return $0.selection.kind != "sticker" && (showFill || showStroke)
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.fillStroke, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

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
        !isBackgroundTrack(context.selection.parent)
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.moveAsClip, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

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
        isBackgroundTrack(context.selection.parent)
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.moveAsOverlay, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

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
      context.eventHandler.send(.openSheet(.libraryReplace { libraryTab }))
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
      ) && $0.engine.block.isAllowedByScope($0.selection.id, key: "fill/change")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.replace, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

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
      return try isGrouped(context.selection.parent)
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.selectGroup, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

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
        try context.engine.block.isAllowedByScope(context.selection.id, key: "lifecycle/destroy") &&
          !isGrouped(context.selection.parent)
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

  static func editText(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.enterTextEditModeForSelection) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Edit") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.editText },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try $0.selection.type == .text &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "text/edit")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.editText, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func formatText(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(.formatText())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Format") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.formatText },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try $0.selection.type == .text &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "text/character")
    }
  ) -> some InspectorBar.Item {
    InspectorBar.Button(id: ID.formatText, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func shape(
    action: @escaping InspectorBar.Context.To<Void> = { $0.eventHandler.send(.openSheet(.shape())) },
    @ViewBuilder title: @escaping InspectorBar.Context.To<some View> = { _ in Text("Shape") },
    @ViewBuilder icon: @escaping InspectorBar.Context.To<some View> = { _ in Image.imgly.shape },
    isEnabled: @escaping InspectorBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping InspectorBar.Context.To<Bool> = {
      try ($0.selection.fillType != .image || $0.selection.kind != "sticker") &&
        $0.engine.block.isAllowedByScope($0.selection.id, key: "shape/change") &&
        $0.engine.block.supportsShape($0.selection.id) &&
        [.line, .star, .polygon, .rect].contains(
          ShapeType(rawValue: $0.engine.block.getType($0.engine.block.getShape($0.selection.id)))
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
