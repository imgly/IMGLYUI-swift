import IMGLYEngine
import SwiftUI

public extension CanvasMenu {
  /// A namespace for canvas menu buttons.
  enum Buttons {}
}

public extension CanvasMenu.Buttons {
  /// A namespace for canvas menu button IDs.
  enum ID {}
}

public extension CanvasMenu.Buttons.ID {
  /// The id of the ``CanvasMenu/Buttons/bringForward(action:label:isEnabled:isVisible:)`` button.
  static var bringForward: EditorComponentID { "ly.img.component.canvasMenu.button.bringForward" }
  /// The id of the ``CanvasMenu/Buttons/sendBackward(action:label:isEnabled:isVisible:)`` button.
  static var sendBackward: EditorComponentID { "ly.img.component.canvasMenu.button.sendBackward" }
  /// The id of the ``CanvasMenu/Buttons/duplicate(action:label:isEnabled:isVisible:)`` button.
  static var duplicate: EditorComponentID { "ly.img.component.canvasMenu.button.duplicate" }
  /// The id of the ``CanvasMenu/Buttons/delete(action:label:isEnabled:isVisible:)`` button.
  static var delete: EditorComponentID { "ly.img.component.canvasMenu.button.delete" }
  /// The id of the ``CanvasMenu/Buttons/selectGroup(action:label:isEnabled:isVisible:)`` button.
  static var selectGroup: EditorComponentID { "ly.img.component.canvasMenu.button.selectGroup" }
}

public extension CanvasMenu {
  /// A visual element that can be used to separate other content.
  /// - Note: Based on the visibility of ``CanvasMenu/Item``s resulting adjacent dividers are automatically collapsed
  /// into a single divider and dangling leading and trailing dividers are removed.
  struct Divider: Item {
    public let id: EditorComponentID = .init("ly.img.component.canvasMenu.divider", isUnique: false)

    /// Creates a divider.
    public init() {}

    public func body(_: Context) throws -> some View {
      SwiftUI.Divider()
        .overlay(.tertiary)
        .clipped()
    }
  }
}

@MainActor
public extension CanvasMenu.Buttons {
  /// Creates a ``CanvasMenu/Button`` that brings forward the selected design block.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/bringSelectionForward`` event is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a `Label` with localization key
  /// `ly_img_editor_canvas_menu_button_bring_forward` and icon ``IMGLY/bringForward`` is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is only `true` if the selected design block is not
  /// the last reorderable child in the parent design block.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block can be
  /// moved forward or backward.
  /// - Returns: The created button.
  static func bringForward(
    action: @escaping CanvasMenu.Context.To<Void> = { $0.eventHandler.send(.bringSelectionForward) },
    @ViewBuilder label: @escaping CanvasMenu.Context.To<some View> = { _ in
      Label {
        Text(.imgly.localized("ly_img_editor_canvas_menu_button_bring_forward"))
      } icon: {
        Image.imgly.bringForward
      }
    },
    isEnabled: @escaping CanvasMenu.Context.To<Bool> = { $0.selection.siblings.last != $0.selection.block },
    isVisible: @escaping CanvasMenu.Context.To<Bool> = { $0.selection.canMove }
  ) -> some CanvasMenu.Item {
    CanvasMenu.Button(id: ID.bringForward, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``CanvasMenu/Button`` that sends backward the selected design block.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/sendSelectionBackward`` event is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a `Label` with localization key
  /// `ly_img_editor_canvas_menu_button_send_backward` and icon ``IMGLY/sendBackward`` is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is only `true` if the selected design block is not
  /// the first reorderable child in the parent design block.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block can be
  /// moved forward or backward.
  /// - Returns: The created button.
  static func sendBackward(
    action: @escaping CanvasMenu.Context.To<Void> = { $0.eventHandler.send(.sendSelectionBackward) },
    @ViewBuilder label: @escaping CanvasMenu.Context.To<some View> = { _ in
      Label {
        Text(.imgly.localized("ly_img_editor_canvas_menu_button_send_backward"))
      } icon: {
        Image.imgly.sendBackward
      }
    },
    isEnabled: @escaping CanvasMenu.Context.To<Bool> = { $0.selection.siblings.first != $0.selection.block },
    isVisible: @escaping CanvasMenu.Context.To<Bool> = { $0.selection.canMove }
  ) -> some CanvasMenu.Item {
    CanvasMenu.Button(id: ID.sendBackward, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``CanvasMenu/Button`` that duplicates the selected design block.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/duplicateSelection`` event is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a `Label` with localization key
  /// `ly_img_editor_canvas_menu_button_duplicate` and icon ``IMGLY/duplicate`` is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block's engine
  /// scope `"lifecycle/duplicate"` is allowed.
  /// - Returns: The created button.
  static func duplicate(
    action: @escaping CanvasMenu.Context.To<Void> = { $0.eventHandler.send(.duplicateSelection) },
    @ViewBuilder label: @escaping CanvasMenu.Context.To<some View> = { _ in
      Label {
        Text(.imgly.localized("ly_img_editor_canvas_menu_button_duplicate"))
      } icon: {
        Image.imgly.duplicate
      }
    },
    isEnabled: @escaping CanvasMenu.Context.To<Bool> = { _ in true },
    isVisible: @escaping CanvasMenu.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope($0.selection.block, key: "lifecycle/duplicate")
    }
  ) -> some CanvasMenu.Item {
    CanvasMenu.Button(id: ID.duplicate, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``CanvasMenu/Button`` that deletes the selected design block.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/deleteSelection``
  /// event is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a `Label` with localization key
  /// `ly_img_editor_canvas_menu_button_delete` and icon ``IMGLY/delete`` is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block's engine
  /// scope `"lifecycle/destroy"` is allowed.
  /// - Returns: The created button.
  static func delete(
    action: @escaping CanvasMenu.Context.To<Void> = { $0.eventHandler.send(.deleteSelection) },
    @ViewBuilder label: @escaping CanvasMenu.Context.To<some View> = { _ in
      Label {
        Text(.imgly.localized("ly_img_editor_canvas_menu_button_delete"))
      } icon: {
        Image.imgly.delete
      }
    },
    isEnabled: @escaping CanvasMenu.Context.To<Bool> = { _ in true },
    isVisible: @escaping CanvasMenu.Context.To<Bool> = {
      try $0.engine.block.isAllowedByScope($0.selection.block, key: "lifecycle/destroy")
    }
  ) -> some CanvasMenu.Item {
    CanvasMenu.Button(id: ID.delete, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``CanvasMenu/Button`` that selects the group design block containing the selected design block.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/selectGroupForSelection`` event is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a `Label` with localization key
  /// `ly_img_editor_canvas_menu_button_select_group`, icon ``IMGLY/selectGroup``, and style ``IMGLY/canvasMenu(_:)`` is
  /// used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` if the selected design block is part
  /// of a group.
  /// - Returns: The created button.
  static func selectGroup(
    action: @escaping CanvasMenu.Context.To<Void> = { $0.eventHandler.send(.selectGroupForSelection) },
    @ViewBuilder label: @escaping CanvasMenu.Context.To<some View> = { _ in
      Label {
        Text(.imgly.localized("ly_img_editor_canvas_menu_button_select_group"))
      } icon: {
        Image.imgly.selectGroup
      }
      .labelStyle(.imgly.canvasMenu(.titleOnly))
    },
    isEnabled: @escaping CanvasMenu.Context.To<Bool> = { _ in true },
    isVisible: @escaping CanvasMenu.Context.To<Bool> = { context in
      @MainActor func isGrouped(_ id: DesignBlockID?) throws -> Bool {
        if let id {
          try context.engine.block.getType(id) == DesignBlockType.group.rawValue
        } else {
          false
        }
      }
      return try isGrouped(context.selection.parentBlock)
    }
  ) -> some CanvasMenu.Item {
    CanvasMenu.Button(id: ID.selectGroup, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }
}
