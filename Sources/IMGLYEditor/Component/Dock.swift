import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore

struct DockKey: EnvironmentKey {
  static let defaultValue: Dock.Items? = nil
}

@_spi(Internal) public extension EnvironmentValues {
  var imglyDock: Dock.Items? {
    get { self[DockKey.self] }
    set { self[DockKey.self] = newValue }
  }
}

@_spi(Unstable) public enum Dock {}

@_spi(Unstable) public extension Dock {
  protocol Item: EditorComponent {}
  typealias Builder = ArrayBuilder<any Item>
  typealias Items = EditorContext.SendableTo<[any Item]>

  struct Button<Label: View>: Item {
    @_spi(Unstable) public let id: EditorComponentID

    let action: EditorContext.To<Void>
    @ViewBuilder let label: EditorContext.To<Label>
    let isEnabled: EditorContext.To<Bool>
    let isVisible: EditorContext.To<Bool>

    @_spi(Unstable) public init(
      id: EditorComponentID,
      action: @escaping EditorContext.To<Void>,
      @ViewBuilder label: @escaping EditorContext.To<Label>,
      isEnabled: @escaping EditorContext.To<Bool> = { _ in true },
      isVisible: @escaping EditorContext.To<Bool> = { _ in true }
    ) {
      self.id = id
      self.action = action
      self.label = label
      self.isEnabled = isEnabled
      self.isVisible = isVisible
    }

    @_spi(Unstable) public func isVisible(_ context: EditorContext) throws -> Bool {
      try isVisible(context)
    }

    @_spi(Unstable) public func body(_ context: EditorContext) throws -> some View {
      let label = try label(context)
      let isDisabled = try !isEnabled(context)
      SwiftUI.Button {
        do {
          try action(context)
        } catch {
          if let interactor = context.eventHandler as? Interactor {
            let error = Error(errorDescription:
              "Could not run action for Dock.Button `\(id.value)`.\nReason:\n\(error.localizedDescription)")
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
