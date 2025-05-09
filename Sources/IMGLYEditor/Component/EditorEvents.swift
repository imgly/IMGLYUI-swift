import IMGLYEngine
import SwiftUI

/// An interface for sending ``EditorEvent``s.
@MainActor
public protocol EditorEventHandler {
  /// A function for sending ``EditorEvent``s.
  /// - Parameter event: The event to send.
  func send(_ event: EditorEvent)
}

/// An editor event that can be sent via ``EditorEventHandler``.
public protocol EditorEvent {}

/// A namespace for ``EditorEvent``s.
public enum EditorEvents {}

public extension EditorEvents {
  /// A share file event.
  struct ShareFile: EditorEvent {
    let url: URL
  }

  /// A namespace for ``EditorEvent``s related to export.
  enum Export {}
}

/// An export progress visualization.
public enum ExportProgress {
  /// Show spinner.
  case spinner
  /// Show relative progress for given percentage value.
  case relative(_ percentage: Float)
}

public extension EditorEvents.Export {
  /// An export progress event.
  struct Progress: EditorEvent {
    let progress: ExportProgress
  }

  /// An export completed event.
  struct Completed: EditorEvent {
    let action: () -> Void
  }
}

public extension EditorEvent where Self == EditorEvents.ShareFile {
  /// Creates an ``EditorEvent`` to show the share sheet for the given URL.
  /// - Parameter url: The URL to share.
  /// - Returns: The created ``EditorEvents/ShareFile`` event.
  static func shareFile(_ url: URL) -> Self { Self(url: url) }
}

public extension EditorEvent where Self == EditorEvents.Export.Progress {
  /// Creates an ``EditorEvent`` to show the export progress sheet for the given state.
  /// - Parameter progress: The export progress state.
  /// - Returns: The created ``EditorEvents/Export/Progress`` event.
  static func exportProgress(_ progress: ExportProgress = .spinner) -> Self { Self(progress: progress) }
}

public extension EditorEvent where Self == EditorEvents.Export.Completed {
  /// Creates an ``EditorEvent`` to show the export completed sheet and to perform the given `action` after dismissal.
  /// - Parameter action: The action to perform after the sheet is dismissed.
  /// - Returns: The created ``EditorEvents/Export/Completed`` event.
  static func exportCompleted(action: @escaping () -> Void = {}) -> Self { Self(action: action) }
}

public extension EditorEvents {
  /// A namespace for ``EditorEvent``s related to sheet handling.
  enum Sheet {}
  /// A namespace for ``EditorEvent``s related to the selected design block.
  enum Selection {}
  /// A namespace for ``EditorEvent``s related to adding assets.
  enum AddFrom {}
}

public extension EditorEvents.Sheet {
  /// A sheet open event.
  struct Open: EditorEvent {
    let type: SheetType
  }

  /// A sheet close event.
  struct Close: EditorEvent {}
}

public extension EditorEvents.Selection {
  /// An event for entering text editing mode for the selected design block.
  struct EnterTextEditMode: EditorEvent {}
  /// An event for duplicating the selected design block.
  struct Duplicate: EditorEvent {}
  /// An event for splitting the selected design block in a video scene.
  struct Split: EditorEvent {}
  /// An event for moving the selected design block into the background track as clip in a video scene.
  struct MoveAsClip: EditorEvent {}
  /// An event for moving the selected design block from the background track to an overlay in a video scene.
  struct MoveAsOverlay: EditorEvent {}
  /// An event for changing selection from a selected group to the first block within that group.
  struct EnterGroup: EditorEvent {}
  /// An event for changing selection from the selected design block to the group design block that contains the
  /// selected design block.
  struct SelectGroup: EditorEvent {}
  /// An event for deleting the selected design block.
  struct Delete: EditorEvent {}
}

public extension EditorEvents.AddFrom {
  /// Default asset source IDs for adding assets based on the asset's ``MediaType``.
  static var defaultAssetSourceIDs: [MediaType: String] { [
    .image: Engine.DemoAssetSource.imageUpload.rawValue,
    .movie: Engine.DemoAssetSource.videoUpload.rawValue,
  ] }

  /// An event for adding assets from the photo roll.
  struct PhotoRoll: EditorEvent {
    let assetSourceIDs: [MediaType: String]
  }

  /// An event for adding assets from the system camera.
  struct SystemCamera: EditorEvent {
    let assetSourceIDs: [MediaType: String]
  }

  /// An event for adding assets from the IMGLY camera.
  struct IMGLYCamera: EditorEvent {
    let assetSourceIDs: [MediaType: String]
  }
}

public extension EditorEvent where Self == EditorEvents.Sheet.Open {
  /// Creates an ``EditorEvent`` to open a sheet of a specific `type`.
  /// - Parameter type: The type of the sheet to open.
  /// - Returns: The created ``EditorEvents/Sheet/Open`` event.
  static func openSheet(type: SheetType) -> Self { Self(type: type) }

  /// Creates an ``EditorEvent`` to open a sheet with any `content`.
  /// - Attention: `List` or `NavigationView` must be used as `content` for non-floating sheet `style`s.
  /// - Parameters:
  ///   - style: The style of the sheet.
  ///   - content: The content of the sheet.
  /// - Returns: The created ``EditorEvents/Sheet/Open`` event.
  static func openSheet(style: SheetStyle, @ViewBuilder content: @escaping () -> some View) -> Self {
    Self(type: SheetTypes.Custom(style: style, content: content))
  }
}

public extension EditorEvent where Self == EditorEvents.Sheet.Close {
  /// Creates an ``EditorEvent`` to close the sheet that is currently open.
  static var closeSheet: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Selection.EnterTextEditMode {
  /// Creates an ``EditorEvent`` to enter text editing mode for the selected design block.
  static var enterTextEditModeForSelection: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Selection.Duplicate {
  /// Creates an ``EditorEvent`` to duplicate the selected design block.
  static var duplicateSelection: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Selection.Split {
  /// Creates an ``EditorEvent`` to split the selected design block in a video scene.
  static var splitSelection: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Selection.MoveAsClip {
  /// Creates an ``EditorEvent`` to move the selected design block into the background track as clip in a video scene.
  static var moveSelectionAsClip: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Selection.MoveAsOverlay {
  /// Creates an ``EditorEvent`` to move the selected design block from the background track to an overlay in a video
  /// scene.
  static var moveSelectionAsOverlay: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Selection.EnterGroup {
  /// Creates an ``EditorEvent`` to change selection from a selected group to the first block within that group.
  static var enterGroupForSelection: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Selection.SelectGroup {
  /// Creates an ``EditorEvent`` to change selection from the selected design block to the group design block that
  /// contains the selected design block.
  static var selectGroupForSelection: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Selection.Delete {
  /// Creates an ``EditorEvent`` to delete the selected design block.
  static var deleteSelection: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.AddFrom.PhotoRoll {
  /// Creates an ``EditorEvent`` to add assets from the photo roll.
  /// - Parameter assetSourceIDs: Added assets will be added to the corresponding asset source based on the asset's
  /// ``MediaType``.
  /// - Returns: The created ``EditorEvents/AddFrom/PhotoRoll`` event.
  static func addFromPhotoRoll(
    to assetSourceIDs: [MediaType: String] = EditorEvents.AddFrom.defaultAssetSourceIDs
  ) -> Self {
    Self(assetSourceIDs: assetSourceIDs)
  }
}

public extension EditorEvent where Self == EditorEvents.AddFrom.SystemCamera {
  /// Creates an ``EditorEvent`` to add assets from the system camera.
  /// - Parameter assetSourceIDs: Added assets will be added to the corresponding asset source based on the asset's
  /// ``MediaType``.
  /// - Returns: The created ``EditorEvents/AddFrom/SystemCamera`` event.
  static func addFromSystemCamera(
    to assetSourceIDs: [MediaType: String] = EditorEvents.AddFrom.defaultAssetSourceIDs
  ) -> Self {
    Self(assetSourceIDs: assetSourceIDs)
  }
}

public extension EditorEvent where Self == EditorEvents.AddFrom.IMGLYCamera {
  /// Creates an ``EditorEvent`` to add assets from the IMGLY camera.
  /// - Parameter assetSourceIDs: Added assets will be added to the corresponding asset source based on the asset's
  /// ``MediaType``.
  /// - Returns: The created ``EditorEvents/AddFrom/IMGLYCamera`` event.
  static func addFromIMGLYCamera(
    to assetSourceIDs: [MediaType: String] = EditorEvents.AddFrom.defaultAssetSourceIDs
  ) -> Self {
    Self(assetSourceIDs: assetSourceIDs)
  }
}
