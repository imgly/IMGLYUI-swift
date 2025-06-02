import SwiftUI

/// A namespace for the editor components.
public enum EditorComponents {}

public extension EditorComponents {
  /// A control that initiates an action.
  struct Button<Label: View, Context: EditorContext>: EditorComponent {
    public let id: EditorComponentID

    let action: Context.To<Void>
    @ViewBuilder let label: Context.To<Label>
    let isEnabled: Context.To<Bool>
    let isVisible: Context.To<Bool>

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
      isVisible: @escaping Context.To<Bool> = { _ in true }
    ) {
      self.id = id
      self.action = action
      self.label = label
      self.isEnabled = isEnabled
      self.isVisible = isVisible
    }

    public func isVisible(_ context: Context) throws -> Bool {
      try isVisible(context)
    }

    public func body(_ context: Context) throws -> some View {
      let label = try label(context)
      let isDisabled = try !isEnabled(context)
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
    }
  }
}
