import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCoreUI

public extension Timeline {
  /// A type for timeline item components.
  protocol Item: EditorComponent where Context == Timeline.ItemContext {}

  /// The context a timeline ``Item`` receives.
  ///
  /// Named apart from `Context` so ``Timeline`` keeps that name free: an `EditorComponent`'s own
  /// `Context` is the one its slot hands it, which is not this.
  struct ItemContext: EditorContext {
    /// The engine of the current editor.
    public let engine: Engine
    public let eventHandler: EditorEventHandler
    /// The configured ``IMGLYCoreUI/AssetLibrary``.
    public let assetLibrary: any AssetLibrary
    /// The state of the current editor, so an item can react to export or view mode.
    public let state: EditorState
    /// The vertical size class of the timeline.
    public let verticalSizeClass: UserInterfaceSizeClass?
    /// Backs the built-in items. Deliberately not public: an integrator drives the timeline
    /// through ``engine`` and ``eventHandler``.
    let interactor: any TimelineInteractor
  }

  /// A builder for building arrays of timeline header ``ItemGroup``s.
  typealias HeaderBuilder = ArrayBuilder<ItemGroup>
  /// A modifier for modifying arrays of timeline header ``Item``s grouped by their
  /// ``ItemPlacement``s.
  typealias Modifier = ArrayModifier<any Item, ItemPlacement>
  /// A closure to build an array of timeline header ``ItemGroup``s.
  typealias Header = ItemContext.To<[ItemGroup]>
  /// A closure to resolve the timeline's ``HeightMode``.
  typealias Height = ItemContext.To<HeightMode>
  /// A closure to build the options of the "Add Clip" button.
  typealias AddClipOptions = ItemContext.To<[AddClipOption]>
  /// A builder for building arrays of "Add Clip" ``AddClipOption``s.
  typealias AddClipOptionsBuilder = ArrayBuilder<AddClipOption>
  /// A closure to build the options of the "Add Audio" button.
  typealias AddAudioOptions = ItemContext.To<[AddAudioOption]>
  /// A builder for building arrays of "Add Audio" ``AddAudioOption``s.
  typealias AddAudioOptionsBuilder = ArrayBuilder<AddAudioOption>
  /// A closure to modify an array of timeline header ``Item``s grouped by their ``ItemPlacement``s.
  typealias Modifications = @MainActor (_ context: ItemContext, _ items: Modifier) throws -> Void
  /// A button timeline ``Item`` component.
  ///
  /// The header applies `.buttonStyle(.plain)`; the button sizes and fonts its own label.
  typealias Button = EditorComponents.Button
  /// A custom timeline ``Item`` component.
  typealias Custom = EditorComponents.Custom
}

extension Timeline.Button: Timeline.Item where Context == Timeline.ItemContext {}
extension Timeline.Custom: Timeline.Item where Context == Timeline.ItemContext {}

public extension Timeline {
  /// A type that defines the placement of timeline header ``Item``s contained in an ``ItemGroup``.
  enum ItemPlacement: Hashable {
    /// Placed at the leading edge of the header.
    case leading
    /// Placed in the horizontal center of the header.
    case center
    /// Placed at the trailing edge of the header.
    case trailing
  }

  /// A group of timeline header ``Item``s with a specific ``ItemPlacement``.
  struct ItemGroup {
    let placement: ItemPlacement
    let items: [any Item]

    /// Creates a group of timeline header ``Item``s with a specific placement.
    /// - Parameters:
    ///   - placement: The placement of the items.
    ///   - items: A builder closure to evaluate the items that should be added to the group.
    public init(placement: ItemPlacement, @ArrayBuilder<any Item> items: () -> [any Item]) {
      self.placement = placement
      self.items = items()
    }
  }
}

public extension Timeline.Modifier where Group == Timeline.ItemPlacement {
  /// Appends an array of `elements` to a placement group.
  ///
  /// Prefer this over ``ArrayModifier/addAfter(id:_:)`` when the position only has to be "at the
  /// end": anchoring on a built-in id throws once that item is removed or renamed.
  /// - Parameters:
  ///   - placement: The placement of the elements.
  ///   - elements: A builder closure to evaluate the elements that should be appended.
  func addLast(placement: Timeline.ItemPlacement, @ArrayBuilder<Element> _ elements: () -> [Element]) {
    toAddLast[placement, default: []].append(contentsOf: elements())
  }

  /// Prepends an array of `elements` to a placement group.
  ///
  /// Prefer this over ``ArrayModifier/addBefore(id:_:)`` when the position only has to be "at the
  /// start": anchoring on a built-in id throws once that item is removed or renamed.
  /// - Parameters:
  ///   - placement: The placement of the elements.
  ///   - elements: A builder closure to evaluate the elements that should be prepended.
  func addFirst(placement: Timeline.ItemPlacement, @ArrayBuilder<Element> _ elements: () -> [Element]) {
    toAddFirst[placement, default: []].insert(contentsOf: elements(), at: 0)
  }
}

@MainActor
extension Timeline.ItemContext {
  /// Builds the context for the timeline ``Timeline/Item``s of one slot.
  ///
  /// Shared by the header (`PlayerBarView`) and the body (`TimelineContentView`) so both resolve
  /// the context the same way.
  /// - Returns: `nil` while the engine is unavailable, in which case no item can render.
  static func make(
    interactor: Interactor,
    editorEnvironment: EditorEnvironment,
    verticalSizeClass: UserInterfaceSizeClass?,
  ) -> Timeline.ItemContext? {
    guard let engine = interactor.engine else { return nil }
    let assetLibrary = AnyAssetLibrary(
      erasing: editorEnvironment.makeAssetLibrary(defaultCategories: AssetLibraryCategory.defaultCategories),
    )
    return .init(
      engine: engine,
      eventHandler: interactor,
      assetLibrary: assetLibrary,
      state: BottomPanel.State(
        isCreating: interactor.isCreating,
        isExporting: interactor.isExporting,
        viewMode: interactor.viewMode,
      ),
      verticalSizeClass: verticalSizeClass,
      interactor: interactor,
    )
  }

  /// The items that ``EditorComponent/isVisible(_:)`` allows, in order.
  ///
  /// Resolve visibility once, before laying items out, so that placement cannot be computed from
  /// items that never render.
  func visible(_ items: [any Timeline.Item]) throws -> [any Timeline.Item] {
    try items.filter { try $0.isVisible(self) }
  }
}
