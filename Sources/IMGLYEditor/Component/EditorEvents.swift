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

  /// An event before closing the editor
  struct OnClose: EditorEvent {}

  /// An event for closing the editor.
  struct CloseEditor: EditorEvent {}

  /// An event for showing a confirmation alert when closing the editor with unsaved changes.
  struct ShowCloseConfirmationAlert: EditorEvent {}

  /// An event for showing a error alert when closing the editor with an error.
  struct ShowErrorAlert: EditorEvent {
    let error: Swift.Error
    let onDismiss: () -> Void
  }

  /// An event for setting the view mode of the editor.
  struct SetViewMode: EditorEvent {
    let viewMode: EditorViewMode
  }

  /// An event for setting extra zoom insets on the canvas.
  struct SetExtraCanvasInsets: EditorEvent {
    let insets: CGFloat
  }

  /// An event for setting minimum and maximum video duration constraints.
  struct SetVideoDurationConstraints: EditorEvent {
    let minimumVideoDuration: TimeInterval?
    let maximumVideoDuration: TimeInterval?
  }

  /// An event for showing an alert when the video is below the minimum duration.
  struct ShowVideoMinLengthAlert: EditorEvent {
    let minimumVideoDuration: TimeInterval
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
  /// An event for starting an export process.
  struct Start: EditorEvent {}

  /// An event for canceling the export process if it is running.
  struct Cancel: EditorEvent {}

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

public extension EditorEvent where Self == EditorEvents.OnClose {
  /// Creates an ``EditorEvent`` to trigger the onClose callback.
  /// - Returns: The created ``EditorEvents/OnClose`` event.
  static var onClose: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.CloseEditor {
  /// Creates an ``EditorEvent`` to close the editor.
  static var closeEditor: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.ShowCloseConfirmationAlert {
  /// Creates an ``EditorEvent`` to show the close confirmation alert.
  static var showCloseConfirmationAlert: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.ShowErrorAlert {
  /// Creates an ``EditorEvent`` to show the error alert.
  static func showErrorAlert(
    _ error: Swift.Error,
    _ onDismiss: @escaping () -> Void = {},
  ) -> Self {
    Self(error: error, onDismiss: onDismiss)
  }
}

public extension EditorEvent where Self == EditorEvents.SetViewMode {
  /// Creates an ``EditorEvent`` to set the view mode of the editor.
  /// - Note: Some view modes may look weird or cause unexpected behaviors in some of the solutions. Please see the
  /// ``EditorViewMode``s for recommendations.
  /// - Parameter viewMode: The view mode to set.
  /// - Returns: The created ``EditorEvents/SetViewMode`` event.
  static func setViewMode(_ viewMode: EditorViewMode) -> Self { Self(viewMode: viewMode) }
}

public extension EditorEvent where Self == EditorEvents.SetExtraCanvasInsets {
  /// Creates an ``EditorEvent`` to set extra zoom insets for the canvas..
  /// - Parameter insets: The extra insets to set.
  /// - Returns: The created ``EditorEvents/SetExtraCanvasInsets`` event.
  static func setExtraCanvasInsets(_ insets: CGFloat) -> Self { Self(insets: insets) }
}

public extension EditorEvent where Self == EditorEvents.SetVideoDurationConstraints {
  /// Creates an ``EditorEvent`` to set minimum and maximum video duration constraints.
  /// - Parameters:
  ///   - minimumVideoDuration: The minimum duration in seconds. Set to `nil` to disable.
  ///   - maximumVideoDuration: The maximum duration in seconds. Set to `nil` to disable.
  /// - Returns: The created ``EditorEvents/SetVideoDurationConstraints`` event.
  static func setVideoDurationConstraints(
    minimumVideoDuration: TimeInterval?,
    maximumVideoDuration: TimeInterval?,
  ) -> Self {
    Self(minimumVideoDuration: minimumVideoDuration, maximumVideoDuration: maximumVideoDuration)
  }
}

public extension EditorEvent where Self == EditorEvents.ShowVideoMinLengthAlert {
  /// Creates an ``EditorEvent`` to show an alert when the video is below the minimum duration.
  /// - Parameter minimumVideoDuration: The minimum duration in seconds.
  /// - Returns: The created ``EditorEvents/ShowVideoMinLengthAlert`` event.
  static func showVideoMinLengthAlert(minimumVideoDuration: TimeInterval) -> Self {
    Self(minimumVideoDuration: minimumVideoDuration)
  }
}

public extension EditorEvent where Self == EditorEvents.Export.Start {
  /// Creates an ``EditorEvent`` to start the export process. This event triggers the ``IMGLY/onExport(_:)`` callback.
  static var startExport: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Export.Cancel {
  /// Creates an ``EditorEvent`` to cancel the export process if it is running.
  static var cancelExport: Self { Self() }
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
  /// A namespace for ``EditorEvent``s related to navigation inside the editor .
  enum Navigation {}
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
  /// An event for bringing forward the selected design block.
  struct BringForward: EditorEvent {}
  /// An event for sending backward the selected design block.
  struct SendBackward: EditorEvent {}
}

public extension EditorEvents.AddFrom {
  /// Default asset source IDs for adding assets based on the asset's ``MediaType``.
  static var defaultAssetSourceIDs: [MediaType: String] { [
    .image: Engine.DemoAssetSource.imageUpload.rawValue,
    .movie: Engine.DemoAssetSource.videoUpload.rawValue,
  ] }

  /// An event for adding assets from the photo roll.
  /// The behavior depends on the mode passed to ``PhotoRollAssetSource``:
  /// - `photosPicker` (default): Opens system photos picker (no permissions required)
  /// - `fullLibraryAccess`: Opens full photo library (requires permissions)
  struct PhotoRoll: EditorEvent {}

  /// An event for adding assets from the system photo roll.
  @available(*, deprecated, message: """
  Deprecated in v1.66.0. Please see the changelog for migration details:
  https://img.ly/docs/cesdk/changelog/v1-66-0/
  """)
  struct SystemPhotoRoll: EditorEvent {
    let assetSourceIDs: [MediaType: String]
  }

  /// An event for adding assets from the photo roll library sheet.
  @available(*, deprecated, message: """
  Deprecated in v1.66.0. Please see the changelog for migration details:
  https://img.ly/docs/cesdk/changelog/v1-66-0/
  """)
  struct IMGLYPhotoRoll: EditorEvent {}

  /// An event for adding assets from the system camera.
  struct SystemCamera: EditorEvent {
    let assetSourceIDs: [MediaType: String]
  }

  /// An event for adding assets from the IMGLY camera.
  struct IMGLYCamera: EditorEvent {
    let assetSourceIDs: [MediaType: String]
  }
}

public extension EditorEvents.Navigation {
  /// An event for navigating to the previous page.
  struct ToPreviousPage: EditorEvent {}

  /// An event for navigating to the next page.
  struct ToNextPage: EditorEvent {}
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
  ///   - associatedEditMode: The edit mode associated with this sheet. It will be automatically applied.
  ///   - content: The content of the sheet.
  /// - Returns: The created ``EditorEvents/Sheet/Open`` event.
  static func openSheet(
    style: SheetStyle,
    associatedEditMode: IMGLYEngine.EditMode? = nil,
    @ViewBuilder content: @escaping () -> some View,
  ) -> Self {
    Self(type: SheetTypes.Custom(style: style, content: content, associatedEditMode: associatedEditMode))
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

public extension EditorEvent where Self == EditorEvents.Selection.BringForward {
  /// Creates an ``EditorEvent`` to bring forward the selected design block.
  static var bringSelectionForward: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Selection.SendBackward {
  /// Creates an ``EditorEvent`` to send backward the selected design block.
  static var sendSelectionBackward: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.AddFrom.PhotoRoll {
  /// Creates an ``EditorEvent`` to add assets from the photo roll.
  ///
  /// The behavior depends on the mode passed to ``PhotoRollAssetSource``:
  /// - `photosPicker` (default): Opens system photos picker (no permissions required)
  /// - `fullLibraryAccess`: Opens full photo library (requires permissions)
  ///
  /// - Returns: The created ``EditorEvents/AddFrom/PhotoRoll`` event.
  static var addFromPhotoRoll: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.AddFrom.SystemPhotoRoll {
  /// Creates an ``EditorEvent`` to add assets from the system photo roll.
  /// - Parameter assetSourceIDs: Added assets will be added to the corresponding asset source based on the asset's
  /// ``MediaType``.
  /// - Returns: The created ``EditorEvents/AddFrom/SystemPhotoRoll`` event.
  @available(*, deprecated, message: """
  Deprecated in v1.66.0. Please see the changelog for migration details:
  https://img.ly/docs/cesdk/changelog/v1-66-0/
  """)
  static func addFromSystemPhotoRoll(
    to assetSourceIDs: [MediaType: String] = EditorEvents.AddFrom.defaultAssetSourceIDs,
  ) -> Self {
    Self(assetSourceIDs: assetSourceIDs)
  }
}

public extension EditorEvent where Self == EditorEvents.AddFrom.IMGLYPhotoRoll {
  /// Creates an ``EditorEvent`` to add assets from the photo roll library sheet.
  /// - Returns: The created ``EditorEvents/AddFrom/IMGLYPhotoRoll`` event.
  @available(*, deprecated, message: """
  Deprecated in v1.66.0. Please see the changelog for migration details:
  https://img.ly/docs/cesdk/changelog/v1-66-0/
  """)
  static var addFromIMGLYPhotoRoll: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.AddFrom.SystemCamera {
  /// Creates an ``EditorEvent`` to add assets from the system camera.
  /// - Parameter assetSourceIDs: Added assets will be added to the corresponding asset source based on the asset's
  /// ``MediaType``.
  /// - Returns: The created ``EditorEvents/AddFrom/SystemCamera`` event.
  static func addFromSystemCamera(
    to assetSourceIDs: [MediaType: String] = EditorEvents.AddFrom.defaultAssetSourceIDs,
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
    to assetSourceIDs: [MediaType: String] = EditorEvents.AddFrom.defaultAssetSourceIDs,
  ) -> Self {
    Self(assetSourceIDs: assetSourceIDs)
  }
}

public extension EditorEvent where Self == EditorEvents.Navigation.ToPreviousPage {
  /// Creates an ``EditorEvent`` to navigate to the previous page.
  static var navigateToPreviousPage: Self { Self() }
}

public extension EditorEvent where Self == EditorEvents.Navigation.ToNextPage {
  /// Creates an ``EditorEvent`` to navigate to the next page.
  static var navigateToNextPage: Self { Self() }
}

public extension EditorEvents {
  /// An event for applying a force crop preset to a block.
  struct ApplyForceCrop: EditorEvent {
    let blockID: DesignBlockID
    let presetCandidates: [ForceCropPreset]
    let mode: ForceCropMode
  }
}

public extension EditorEvent where Self == EditorEvents.ApplyForceCrop {
  /// Creates an ``EditorEvent`` to apply a force crop preset to a design block.
  /// - Parameters:
  ///   - blockID: The ID of the block to apply the crop to.
  ///   - presetCandidates: Array of crop preset candidates. The best matching preset will be automatically selected.
  ///   - mode: Defines the behavior - `.silent`, `.always`, or `.ifNeeded`.
  /// - Returns: The created ``EditorEvents/ApplyForceCrop`` event.
  static func applyForceCrop(
    to blockID: DesignBlockID,
    with presetCandidates: [ForceCropPreset],
    mode: ForceCropMode,
  ) -> Self {
    Self(blockID: blockID, presetCandidates: presetCandidates, mode: mode)
  }
}
