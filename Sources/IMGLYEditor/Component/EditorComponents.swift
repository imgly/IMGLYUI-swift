import SwiftUI

/// A namespace for the editor components.
public enum EditorComponents {}

public extension EditorComponents {
  /// A control that initiates an action.
  struct Button<Label: View, Context: EditorContext, Modifier: ViewModifier>: EditorComponent {
    public let id: EditorComponentID

    let action: Context.To<Void>
    @ViewBuilder let label: Context.To<Label>
    let isEnabled: Context.To<Bool>
    let isVisible: Context.To<Bool>
    let modifier: Context.To<Modifier>

    /// Creates a button that displays a custom label.
    /// - Parameters:
    ///   - id: A unique identifier for the button.
    ///   - action: The action to perform when the user triggers the button.
    ///   - label: A view that describes the purpose of the button’s `action`.
    ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
    ///   - isVisible: Whether the button is visible. By default, it is always `true`.
    /// - Note: Don't encode the visibility in the `label` view. Use `isVisible` instead.
    public init(
      id: EditorComponentID,
      action: @escaping Context.To<Void>,
      @ViewBuilder label: @escaping Context.To<Label>,
      isEnabled: @escaping Context.To<Bool> = { _ in true },
      isVisible: @escaping Context.To<Bool> = { _ in true },
      modifier: @escaping Context.To<Modifier>
    ) {
      self.id = id
      self.action = action
      self.label = label
      self.isEnabled = isEnabled
      self.isVisible = isVisible
      self.modifier = modifier
    }

    public func isVisible(_ context: Context) throws -> Bool {
      try isVisible(context)
    }

    public func body(_ context: Context) throws -> some View {
      let label = try label(context)
      let isDisabled = try !isEnabled(context)
      let modifier = try modifier(context)

      SwiftUI.Button {
        do {
          try action(context)
        } catch {
          if let interactor = context.eventHandler as? Interactor {
            let error = EditorError(
              "Could not run action for EditorComponents.Button `\(id.value)`.\nReason:\n\(error.localizedDescription)"
            )
            interactor.handleError(error)
          }
        }
      } label: {
        label
      }
      .disabled(isDisabled)
      .modifier(modifier)
    }
  }

  /// A custom view.
  struct Custom<Content: View, Context: EditorContext>: EditorComponent {
    public let id: EditorComponentID

    @ViewBuilder let content: Context.To<Content>
    let isEnabled: Context.To<Bool>
    let isVisible: Context.To<Bool>

    /// Creates a custom view that displays custom content.
    /// - Parameters:
    ///   - id: A unique identifier for the item.
    ///   - content: A view that describes the purpose of item.
    ///   - isEnabled: Whether the item is enabled. By default, it is always `true`.
    ///   - isVisible: Whether the item is visible. By default, it is always `true`.
    /// - Note: Don't encode the visibility in the `content` view. Use `isVisible` instead.
    public init(
      id: EditorComponentID,
      @ViewBuilder content: @escaping Context.To<Content>,
      isEnabled: @escaping Context.To<Bool> = { _ in true },
      isVisible: @escaping Context.To<Bool> = { _ in true }
    ) {
      self.id = id
      self.content = content
      self.isEnabled = isEnabled
      self.isVisible = isVisible
    }

    public func isVisible(_ context: Context) throws -> Bool {
      try isVisible(context)
    }

    public func body(_ context: Context) throws -> some View {
      let content = try content(context)
      let isDisabled = try !isEnabled(context)

      content
        .disabled(isDisabled)
    }
  }
}

public extension EditorComponents.Button where Modifier == EmptyModifier {
  init(
    id: EditorComponentID,
    action: @escaping Context.To<Void>,
    @ViewBuilder label: @escaping Context.To<Label>,
    isEnabled: @escaping Context.To<Bool> = { _ in true },
    isVisible: @escaping Context.To<Bool> = { _ in true },
  ) {
    self.id = id
    self.action = action
    self.label = label
    self.isEnabled = isEnabled
    self.isVisible = isVisible
    modifier = { _ in EmptyModifier() }
  }
}
