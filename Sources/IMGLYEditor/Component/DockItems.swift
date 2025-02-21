import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

public extension Dock {
  /// A namespace for dock buttons.
  enum Buttons {}
}

public extension Dock.Buttons {
  /// A namespace for dock buttons IDs.
  enum ID {}
}

public extension Dock.Buttons.ID {
  /// The id of the elements library button.
  static var elementsLibrary: EditorComponentID { "ly.img.component.dock.button.elementsLibrary" }
  /// The id of the audio library button.
  static var audioLibrary: EditorComponentID { "ly.img.component.dock.button.audioLibrary" }
  /// The id of the images library button.
  static var imagesLibrary: EditorComponentID { "ly.img.component.dock.button.imagesLibrary" }
  /// The id of the text library button.
  static var textLibrary: EditorComponentID { "ly.img.component.dock.button.textLibrary" }
  /// The id of the shapes library button.
  static var shapesLibrary: EditorComponentID { "ly.img.component.dock.button.shapesLibrary" }
  /// The id of the stickers library button.
  static var stickersLibrary: EditorComponentID { "ly.img.component.dock.button.stickersLibrary" }

  /// The id of the overlays library button
  static var overlaysLibrary: EditorComponentID { "ly.img.component.dock.button.overlaysLibrary" }
  /// The id of the stickers and shapes library button.
  static var stickersAndShapesLibrary: EditorComponentID { "ly.img.component.dock.button.stickersAndShapesLibrary" }

  /// The id of the photo roll button.
  static var photoRoll: EditorComponentID { "ly.img.component.dock.button.photoRoll" }
  /// The id of the system camera button.
  static var systemCamera: EditorComponentID { "ly.img.component.dock.button.systemCamera" }
  /// The id of the imgly camera button.
  static var imglyCamera: EditorComponentID { "ly.img.component.dock.button.imglyCamera" }
  /// The id of the voiceover button.
  static var voiceover: EditorComponentID { "ly.img.component.dock.button.voiceover" }

  /// The id of the reorder button.
  static var reorder: EditorComponentID { "ly.img.component.dock.button.reorder" }
  /// The id of the adjustments button.
  static var adjustments: EditorComponentID { "ly.img.component.dock.button.adjustments" }
  /// The id of the filter button.
  static var filter: EditorComponentID { "ly.img.component.dock.button.filter" }
  /// The id of the effect button.
  static var effect: EditorComponentID { "ly.img.component.dock.button.effect" }
  /// The id of the blur button.
  static var blur: EditorComponentID { "ly.img.component.dock.button.blur" }
  /// The id of the crop button.
  static var crop: EditorComponentID { "ly.img.component.dock.button.crop" }
}

@MainActor
public extension Dock.Buttons {
  static func elementsLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(.libraryAdd { context.assetLibrary.elementsTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Elements") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addElement },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.elementsLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func audioLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(.libraryAdd { context.assetLibrary.audioTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Audio") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addAudio },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.audioLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func imagesLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(.libraryAdd { context.assetLibrary.imagesTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Image") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addImage },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.imagesLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func textLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(.libraryAdd(style: .addAsset(detent: .imgly.medium)) {
        context.assetLibrary.textTab
      }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Text") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addText },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.textLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func shapesLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(.libraryAdd { context.assetLibrary.shapesTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Shape") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addShape },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.shapesLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func stickersLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(.libraryAdd { context.assetLibrary.stickersTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Sticker") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addSticker },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.stickersLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func overlaysLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(.libraryAdd { context.assetLibrary.overlaysTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Overlay") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addVideo },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.overlaysLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func stickersAndShapesLibrary(
    action: @escaping Dock.Context.To<Void> = { context in
      context.eventHandler.send(.openSheet(.libraryAdd { context.assetLibrary.stickersAndShapesTab }))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Sticker") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addSticker },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.stickersAndShapesLibrary, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func photoRoll(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.addFromPhotoRoll()) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Photo Roll") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { context in
      let isVideoScene = try context.engine.scene.getMode() == .video
      return isVideoScene ? Image.imgly.addPhotoRollBackground : Image.imgly.addPhotoRollForeground
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.photoRoll, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func systemCamera(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.addFromSystemCamera()) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Camera") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { context in
      let isVideoScene = try context.engine.scene.getMode() == .video
      return isVideoScene ? Image.imgly.addCameraBackground : Image.imgly.addCameraForeground
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.systemCamera, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func imglyCamera(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.addFromIMGLYCamera()) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Camera") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { context in
      let isVideoScene = try context.engine.scene.getMode() == .video
      return isVideoScene ? Image.imgly.addCameraBackground : Image.imgly.addCameraForeground
    },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.imglyCamera, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func voiceover(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.openSheet(.voiceover())) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Voiceover") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.addVoiceover },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { _ in true }
  ) -> some Dock.Item {
    Dock.Button(id: ID.voiceover, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func reorder(
    action: @escaping Dock.Context.To<Void> = { $0.eventHandler.send(.openSheet(.reorder())) },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Reorder") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.reorder },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = { context in
      let backgroundTrack = try context.engine.block.find(byType: .track).filter {
        try context.engine.block.isAlwaysOnBottom($0)
      }.first
      guard let backgroundTrack else {
        return false
      }
      return try context.engine.block.getChildren(backgroundTrack).count > 1
    }
  ) -> some Dock.Item {
    Dock.Button(id: ID.reorder, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func adjustments(
    action: @escaping Dock.Context.To<Void> = {
      try $0.eventHandler.send(.openSheet(.adjustments(id: nonNil($0.engine.scene.getCurrentPage()))))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Adjustments") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.adjustments },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope(nonNil($0.engine.scene.getCurrentPage()), key: "appearance/adjustments")
    }
  ) -> some Dock.Item {
    Dock.Button(id: ID.adjustments, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func filter(
    action: @escaping Dock.Context.To<Void> = {
      try $0.eventHandler.send(.openSheet(.filter(id: nonNil($0.engine.scene.getCurrentPage()))))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Filter") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.filter },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope(nonNil($0.engine.scene.getCurrentPage()), key: "appearance/filter")
    }
  ) -> some Dock.Item {
    Dock.Button(id: ID.filter, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func effect(
    action: @escaping Dock.Context.To<Void> = {
      try $0.eventHandler.send(.openSheet(.effect(id: nonNil($0.engine.scene.getCurrentPage()))))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Effect") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.effect },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope(nonNil($0.engine.scene.getCurrentPage()), key: "appearance/effect")
    }
  ) -> some Dock.Item {
    Dock.Button(id: ID.effect, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func blur(
    action: @escaping Dock.Context.To<Void> = {
      try $0.eventHandler.send(.openSheet(.blur(id: nonNil($0.engine.scene.getCurrentPage()))))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Blur") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.blur },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope(nonNil($0.engine.scene.getCurrentPage()), key: "appearance/blur")
    }
  ) -> some Dock.Item {
    Dock.Button(id: ID.blur, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }

  static func crop(
    action: @escaping Dock.Context.To<Void> = {
      try $0.eventHandler.send(.openSheet(.crop(id: nonNil($0.engine.scene.getCurrentPage()))))
    },
    @ViewBuilder title: @escaping Dock.Context.To<some View> = { _ in Text("Crop") },
    @ViewBuilder icon: @escaping Dock.Context.To<some View> = { _ in Image.imgly.crop },
    isEnabled: @escaping Dock.Context.To<Bool> = { _ in true },
    isVisible: @escaping Dock.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope(nonNil($0.engine.scene.getCurrentPage()), key: "layer/crop")
    }
  ) -> some Dock.Item {
    Dock.Button(id: ID.crop, action: action, label: { context in
      let title = try title(context)
      let icon = try icon(context)
      Label { title } icon: { icon }
    }, isEnabled: isEnabled, isVisible: isVisible)
  }
}
