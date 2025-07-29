import IMGLYEngine
import SwiftUI

@_spi(Internal) public extension EnvironmentValues {
  @Entry var imglyNavigationBarItems: NavigationBar.Items?
  @Entry var imglyNavigationBarModifications: NavigationBar.Modifications?
}

/// A namespace for the navigation bar component.
public enum NavigationBar {
  struct State: EditorState {
    let isCreating: Bool
    let isExporting: Bool
    let viewMode: EditorViewMode
  }
}

public extension NavigationBar {
  /// A type for navigation bar item components.
  protocol Item: EditorComponent where Context == NavigationBar.Context {}
  /// A builder for building arrays of navigation bar ``ItemGroup``s.
  typealias Builder = ArrayBuilder<ItemGroup>
  /// A modifier for modifying arrays of navigation bar ``Item``s grouped by their ``ItemPlacement``s.
  typealias Modifier = ArrayModifier<any Item, ItemPlacement>

  /// The context of navigation bar components.
  struct Context: EditorContext {
    /// The engine of the current editor. It is `nil` as long as the engine is being created before the
    /// ``IMGLY/onCreate(_:)``callback is run.
    public let engine: Engine?
    public let eventHandler: EditorEventHandler
    /// The state of the current editor.
    public let state: EditorState
    /// The asset library configured with the ``IMGLY/assetLibrary(_:)`` view modifier.
    public let assetLibrary: any AssetLibrary
  }

  /// A closure to build an array of navigation bar ``ItemGroup``s.
  typealias Items = Context.SendableTo<[ItemGroup]>
  /// A closure to modify an array of navigation bar ``Item``s grouped by their ``ItemPlacement``s..
  typealias Modifications = @Sendable @MainActor (_ context: Context, _ items: Modifier) throws -> Void
  /// A button navigation bar ``Item`` component.
  typealias Button = EditorComponents.Button

  /// A group of navigation bar ``Item``s with a specific ``ItemPlacement``.
  struct ItemGroup {
    let placement: ItemPlacement
    let items: [any Item]

    /// Creates a group of navigation bar ``Item``s with a specific placement.
    /// - Parameters:
    ///   - placement: The placement of the items.
    ///   - items: A builder closure to evaluate the items that should be added to the group.
    public init(placement: ItemPlacement, @ArrayBuilder<any Item> items: () -> [any Item]) {
      self.placement = placement
      self.items = items()
    }
  }

  /// A type that defines the placement of navigation bar ``Item``s  contained in an ``ItemGroup``. It is mapped to the
  /// corresponding SwiftUI `ToolbarItemPlacement`s used for `ToolbarItemGroup`s.
  enum ItemPlacement {
    case principal
    case topBarLeading
    case topBarTrailing
  }
}

extension NavigationBar.Button: NavigationBar.Item where Context == NavigationBar.Context {}

public extension NavigationBar.Modifier where Group == NavigationBar.ItemPlacement {
  /// Appends an array of `elements` to a placement group.
  /// - Parameters:
  ///   - placement: The placement of the elements.
  ///   - elements: A builder closure to evaluate the elements that should be appended.
  func addLast(placement: NavigationBar.ItemPlacement, @ArrayBuilder<Element> _ elements: () -> [Element]) {
    toAddLast[placement, default: []].append(contentsOf: elements())
  }

  /// Prepends an array of `elements` to a placement group.
  /// - Parameters:
  ///   - placement: The placement of the elements.
  ///   - elements: A builder closure to evaluate the elements that should be prepended.
  func addFirst(placement: NavigationBar.ItemPlacement, @ArrayBuilder<Element> _ elements: () -> [Element]) {
    toAddFirst[placement, default: []].insert(contentsOf: elements(), at: 0)
  }
}
