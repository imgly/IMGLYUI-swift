import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public extension EnvironmentValues {
  @Entry var imglyCanvasMenuItems: CanvasMenu.Items?
  @Entry var imglyCanvasMenuModifications: CanvasMenu.Modifications?
}

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
    /// The asset library configured with the ``IMGLY/assetLibrary(_:)`` view modifier.
    public let assetLibrary: any AssetLibrary
    /// The current selection.
    /// - Note: Prefer using this provided selection property instead of querying the same data from engine because the
    /// engine values will update immediately on changes whereas this provided `selection` is cached for the
    /// presentation time of the canvas menu including its appear and disappear animations.
    public let selection: Selection
  }

  /// A closure to build an array of canvas menu ``Item``s.
  typealias Items = Context.SendableTo<[any Item]>
  /// A closure to modify an array of canvas menu ``Item``s.
  typealias Modifications = @Sendable @MainActor (_ context: Context, _ items: Modifier) throws -> Void
  /// A button canvas menu ``Item`` component.
  typealias Button = EditorComponents.Button
}

extension CanvasMenu.Button: CanvasMenu.Item where Context == CanvasMenu.Context {}

public extension CanvasMenu.Context {
  /// Cached properties of the current selection.
  struct Selection {
    /// The id of the current selected design block.
    public let block: DesignBlockID
    /// The id of the parent design block of the current selected design ``block``.
    public let parentBlock: DesignBlockID?
    /// The type of the current selected design ``block``.
    public let type: DesignBlockType?
    /// The fill type of the current selected design ``block``.
    public let fillType: FillType?
    /// The kind of the current selected design ``block``.
    public let kind: String?
    /// The ids of reorderable siblings of the current selected design ``block`` and the current selected design
    /// ``block`` itself sorted in their rendering order: last block is rendered in front of other blocks.
    public let siblings: [DesignBlockID]
    /// Whether the current selected design ``block`` can be moved: forward or backward.
    public let canMove: Bool

    @MainActor
    init(block: DesignBlockID, engine: Engine) throws {
      self.block = block
      parentBlock = try engine.block.getParent(block)
      type = try .init(rawValue: engine.block.getType(block))
      fillType = try engine.block
        .supportsFill(block) ? .init(rawValue: engine.block.getType(engine.block.getFill(block))) : nil
      kind = try engine.block.getKind(block)

      @MainActor func isBackgroundTrack(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try engine.block.getType(id) == DesignBlockType.track.rawValue &&
            engine.block.isAlwaysOnBottom(id)
        } else {
          false
        }
      }
      if let parentBlock {
        siblings = try engine.block.getReorderableChildren(parentBlock, child: block)
      } else {
        siblings = [block]
      }
      let canReorderTrack = try !isBackgroundTrack(parentBlock) && siblings.count > 1
      canMove = try engine.block.isAllowedByScope(block, key: "layer/move") && canReorderTrack
    }
  }
}
