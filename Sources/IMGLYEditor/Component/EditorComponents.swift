import SwiftUI
@_spi(Internal) import struct IMGLYCore.Error

public enum EditorComponents {}

public extension EditorComponents {
  struct Button<Label: View, Context: EditorContext>: EditorComponent {
    public let id: EditorComponentID

    let action: Context.To<Void>
    @ViewBuilder let label: Context.To<Label>
    let isEnabled: Context.To<Bool>
    let isVisible: Context.To<Bool>

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
            let error = Error(errorDescription:
              "Could not run action for EditorComponents.Button `\(id.value)`.\nReason:\n\(error.localizedDescription)")
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
