import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCoreUI

/// A namespace for the canvas menu component.
public enum CanvasMenu {}

public extension CanvasMenu {
  /// A type for canvas menu item components.
  protocol Item: EditorComponent where Context == CanvasMenu.Context {}
  /// A builder for building arrays of canvas menu ``Item``s.
  typealias Builder = ArrayBuilder<any Item>
  /// A modifier for modifying arrays of canvas menu ``Item``s.
  typealias Modifier = ArrayModifier<any Item, None>

  /// The context of canvas menu components.
  struct Context: EditorContext {
    /// The engine of the current editor.
    /// - Note: Prefer using the ``selection`` property for accessing the current selection instead of querying the same
    /// data from engine because the engine values will update immediately on changes whereas this provided
    /// ``selection`` is cached for the presentation time of the canvas menu including its appear and disappear
    /// animations.
    public let engine: Engine
    public let eventHandler: EditorEventHandler
    /// The configured ``IMGLYCoreUI/AssetLibrary``.
    public let assetLibrary: any AssetLibrary
    /// The current selection.
    /// - Note: Prefer using this provided selection property instead of querying the same data from engine because the
    /// engine values will update immediately on changes whereas this provided `selection` is cached for the
    /// presentation time of the canvas menu including its appear and disappear animations.
    public let selection: Selection
  }

  /// A closure to build an array of canvas menu ``Item``s.
  typealias Items = Context.To<[any Item]>
  /// A closure to modify an array of canvas menu ``Item``s.
  typealias Modifications = @MainActor (_ context: Context, _ items: Modifier) throws -> Void
  /// A button canvas menu ``Item`` component.
  typealias Button = EditorComponents.Button
}

extension CanvasMenu.Button: CanvasMenu.Item where Context == CanvasMenu.Context {}

public extension CanvasMenu.Context {
  /// Cached properties of the current selection.
  @MainActor
  struct Selection {
    /// The id of the current selected design block.
    public let block: DesignBlockID
    /// The type of the current selected design ``block``.
    public let type: DesignBlockType?
    /// The fill type of the current selected design ``block``.
    public let fillType: FillType?
    /// The kind of the current selected design ``block``.
    public let kind: String?
    /// The reorderable peers of the current selected design ``block`` *in its current parent*,
    /// sorted in rendering order (last is rendered in front). Use this for enumeration or
    /// display — to gate UI on whether a reorder action would actually change layout, prefer
    /// the engine-aware ``canBringForward`` / ``canSendBackward`` properties below, which
    /// also account for the track pop-out semantics that this list intentionally does not
    /// reflect.
    public let siblings: [DesignBlockID]
    /// `true` when `BlockAPI.bringForward(_:)` would change the block's layout.
    /// Drives per-direction *enabled* state of "bring forward" / layer-up controls.
    public let canBringForward: Bool
    /// `true` when `BlockAPI.bringBackward(_:)` would change the block's layout.
    /// Drives per-direction *enabled* state of "send backward" / layer-down controls.
    public let canSendBackward: Bool
    /// Aggregate visibility gate: `true` when the editor allows reordering this selection at
    /// all (combines `canBringForward || canSendBackward` with the editor scope, the
    /// background-track pin, and the audio-clip exclusion). Drives *visibility* of the
    /// reorder controls; for the per-direction enabled state use ``canBringForward`` /
    /// ``canSendBackward``.
    public let canMove: Bool

    private let engine: Engine

    /// The id of the parent design block of the current selected design ``block``.
    public var parentBlock: DesignBlockID? {
      try? engine.block.getParent(block)
    }

    init(block: DesignBlockID, engine: Engine) throws {
      self.block = block
      self.engine = engine
      type = try .init(rawValue: engine.block.getType(block))
      fillType = try engine.block
        .supportsFill(block) ? .init(rawValue: engine.block.getType(engine.block.getFill(block))) : nil
      kind = try engine.block.getKind(block)

      let initialParent = try engine.block.getParent(block)
      @MainActor func isBackgroundTrack(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try engine.block.getType(id) == DesignBlockType.track.rawValue &&
            engine.block.isPageDurationSource(id)
        } else {
          false
        }
      }
      if let initialParent {
        siblings = try engine.block.getReorderableChildren(initialParent, child: block)
      } else {
        siblings = [block]
      }
      canBringForward = try engine.block.canBringForward(block)
      canSendBackward = try engine.block.canBringBackward(block)
      // Audio (incl. voiceover) clips have no z-order — matches web.
      let isAudio = type == .audio
      let canReorderTrack = try !isAudio && !isBackgroundTrack(initialParent) && (canBringForward || canSendBackward)
      canMove = try engine.block.isAllowedByScope(block, key: "layer/move") && canReorderTrack
    }
  }
}
