import IMGLYEngine
import SwiftUI

/// An interface for sending editor events.
@MainActor
public protocol EditorEventHandler {
  /// A function for sending `EditorEvent`s.
  /// - Parameter event: The event to send.
  func send(_ event: EditorEvent)
}

/// An editor event that can be sent via `EditorEventHandler`.
public protocol EditorEvent {}

/// A namespace for `EditorEvent`s.
public enum EditorEvents {}

public extension EditorEvents {
  /// A share file event.
  struct ShareFile: EditorEvent {
    let url: URL
  }

  /// A namespace for export-related `EditorEvent`s.
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
  /// Show share sheet for given URL.
  static func shareFile(_ url: URL) -> Self { Self(url: url) }
}

public extension EditorEvent where Self == EditorEvents.Export.Progress {
  /// Show export progress sheet for given state.
  static func exportProgress(_ progress: ExportProgress = .spinner) -> Self { Self(progress: progress) }
}

public extension EditorEvent where Self == EditorEvents.Export.Completed {
  /// Show export completed sheet and perform given action after dismissal.
  static func exportCompleted(action: @escaping () -> Void = {}) -> Self { Self(action: action) }
}

@_spi(Unstable) public extension EditorEvents {
  enum Sheet {}
  enum AddFrom {}
}

@_spi(Unstable) public extension EditorEvents.Sheet {
  struct Open: EditorEvent {
    let type: SheetType
  }

  struct Close: EditorEvent {}
}

@_spi(Unstable) public extension EditorEvents.AddFrom {
  static var defaultAssetSourceIDs: [MediaType: String] { [
    .image: Engine.DemoAssetSource.imageUpload.rawValue,
    .movie: Engine.DemoAssetSource.videoUpload.rawValue,
  ] }

  struct PhotoRoll: EditorEvent {
    let assetSourceIDs: [MediaType: String]
  }

  struct SystemCamera: EditorEvent {
    let assetSourceIDs: [MediaType: String]
  }

  struct IMGLYCamera: EditorEvent {
    let assetSourceIDs: [MediaType: String]
  }
}

@_spi(Unstable) public extension EditorEvent where Self == EditorEvents.Sheet.Open {
  static func openSheet(_ type: SheetType) -> Self { Self(type: type) }
  /// Open sheet with any content.
  /// - Attention: `List` or `NavigationView` must be used as `content` for non-floating sheet `style`s.
  static func openSheet(style: SheetStyle, @ViewBuilder content: @escaping () -> some View) -> Self {
    Self(type: SheetTypes.Custom(style: style, content: content))
  }
}

@_spi(Unstable) public extension EditorEvent where Self == EditorEvents.Sheet.Close {
  static var closeSheet: Self { Self() }
}

@_spi(Unstable) public extension EditorEvent where Self == EditorEvents.AddFrom.PhotoRoll {
  static func addFromPhotoRoll(
    to assetSourceIDs: [MediaType: String] = EditorEvents.AddFrom.defaultAssetSourceIDs
  ) -> Self {
    Self(assetSourceIDs: assetSourceIDs)
  }
}

@_spi(Unstable) public extension EditorEvent where Self == EditorEvents.AddFrom.SystemCamera {
  static func addFromSystemCamera(
    to assetSourceIDs: [MediaType: String] = EditorEvents.AddFrom.defaultAssetSourceIDs
  ) -> Self {
    Self(assetSourceIDs: assetSourceIDs)
  }
}

@_spi(Unstable) public extension EditorEvent where Self == EditorEvents.AddFrom.IMGLYCamera {
  static func addFromIMGLYCamera(
    to assetSourceIDs: [MediaType: String] = EditorEvents.AddFrom.defaultAssetSourceIDs
  ) -> Self {
    Self(assetSourceIDs: assetSourceIDs)
  }
}
