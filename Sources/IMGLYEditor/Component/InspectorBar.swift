import IMGLYEngine
import SwiftUI

@_spi(Internal) public extension EnvironmentValues {
  @Entry var imglyInspectorBarItems: InspectorBar.Items?
  @Entry var imglyInspectorBarModifications: InspectorBar.Modifications?
}

/// A namespace for the inspector bar component.
public enum InspectorBar {}

public extension InspectorBar {
  /// A type for inspector bar item components.
  protocol Item: EditorComponent where Context == InspectorBar.Context {}
  /// A builder for building arrays of inspector bar ``Item``s.
  typealias Builder = ArrayBuilder<any Item>
  /// A modifier for modifying arrays of inspector bar ``Item``s.
  typealias Modifier = ArrayModifier<any Item, None>

  /// The context of inspector bar components.
  struct Context: EditorContext {
    /// The engine of the current editor.
    /// - Note: Prefer using the ``selection`` property for accessing the current selection instead of querying the same
    /// data from engine because the engine values will update immediately on changes whereas this provided
    /// ``selection`` is cached for the presentation time of the inspector bar including its appear and disappear
    /// animations.
    public let engine: Engine
    public let eventHandler: EditorEventHandler
    /// The asset library configured with the ``IMGLY/assetLibrary(_:)`` view modifier.
    public let assetLibrary: any AssetLibrary
    /// The current selection.
    /// - Note: Prefer using this provided selection property instead of querying the same data from engine because the
    /// engine values will update immediately on changes whereas this provided `selection` is cached for the
    /// presentation time of the inspector bar including its appear and disappear animations.
    public let selection: Selection
  }

  /// A closure to build an array of inspector bar ``Item``s.
  typealias Items = Context.To<[any Item]>
  /// A closure to modify an array of inspector bar ``Item``s.
  typealias Modifications = @MainActor (_ context: Context, _ items: Modifier) throws -> Void
  /// A button inspector bar ``Item`` component.
  typealias Button = EditorComponents.Button
}

extension InspectorBar.Button: InspectorBar.Item where Context == InspectorBar.Context {}

public extension InspectorBar.Context {
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

    @MainActor
    init(block: DesignBlockID, engine: Engine) throws {
      self.block = block
      parentBlock = try engine.block.getParent(block)
      type = try .init(rawValue: engine.block.getType(block))
      fillType = try engine.block
        .supportsFill(block) ? .init(rawValue: engine.block.getType(engine.block.getFill(block))) : nil
      kind = try engine.block.getKind(block)
    }
  }
}
