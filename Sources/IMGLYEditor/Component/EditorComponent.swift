import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore

@_spi(Unstable) public struct EditorComponentID: Hashable, Sendable {
  let value: String

  @_spi(Unstable) public init(_ value: String) {
    self.value = value
  }
}

extension EditorComponentID: ExpressibleByStringInterpolation {
  @_spi(Unstable) public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}

@_spi(Unstable) public struct EditorContext {
  @_spi(Unstable) public let engine: Engine
  @_spi(Unstable) public let eventHandler: EditorEventHandler
  @_spi(Unstable) public let assetLibrary: any AssetLibrary

  init(_ engine: Engine, _ eventHandler: EditorEventHandler, _ assetLibrary: any AssetLibrary) {
    self.engine = engine
    self.eventHandler = eventHandler
    self.assetLibrary = assetLibrary
  }
}

@_spi(Unstable) public extension EditorContext {
  typealias To<T> = @MainActor (_ context: Self) throws -> T
  typealias SendableTo<T> = @Sendable @MainActor (_ context: Self) throws -> T
}

@_spi(Unstable) public protocol EditorComponent {
  var id: EditorComponentID { get }

  @MainActor
  func isVisible(_ context: EditorContext) throws -> Bool

  associatedtype Body: View

  @MainActor @ViewBuilder
  func body(_ context: EditorContext) throws -> Body
}

@_spi(Unstable) public extension EditorComponent {
  func isVisible(_: EditorContext) throws -> Bool {
    true
  }
}

extension EditorComponent {
  @MainActor
  func nonThrowingBody(_ context: EditorContext) -> any View {
    do {
      return try body(context)
    } catch {
      if let interactor = context.eventHandler as? Interactor {
        let error = Error(errorDescription:
          "Could not create View for EditorComponent `\(id.value)`.\nReason:\n\(error.localizedDescription)")
        interactor.handleErrorWithTask(error)
      }
      return EmptyView()
    }
  }
}
