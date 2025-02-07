import IMGLYEngine
import SwiftUI
@_spi(Internal) import struct IMGLYCore.Error

// MARK: - EditorComponentID

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

// MARK: - EditorContext

@_spi(Unstable) public protocol EditorContext {
  var eventHandler: EditorEventHandler { get }
}

@_spi(Unstable) public extension EditorContext {
  typealias To<T> = @MainActor (_ context: Self) throws -> T
  typealias SendableTo<T> = @Sendable @MainActor (_ context: Self) throws -> T
}

// MARK: - EditorError

@_spi(Unstable) public struct EditorError: LocalizedError {
  @_spi(Unstable) public let errorDescription: String?

  @_spi(Unstable) public init(_ errorDescription: String?) {
    self.errorDescription = errorDescription
  }
}

// MARK: - EditorComponent

@_spi(Unstable) public protocol EditorComponent {
  var id: EditorComponentID { get }

  associatedtype Context: EditorContext

  @MainActor
  func isVisible(_ context: Context) throws -> Bool

  associatedtype Body: View

  @MainActor @ViewBuilder
  func body(_ context: Context) throws -> Body
}

@_spi(Unstable) public extension EditorComponent {
  func isVisible(_: Context) throws -> Bool {
    true
  }
}

extension EditorComponent {
  @MainActor
  func nonThrowingBody(_ context: Context) -> any View {
    do {
      return try body(context)
    } catch {
      if let interactor = context.eventHandler as? Interactor {
        let error = EditorError(
          "Could not create View for EditorComponent `\(id.value)`.\nReason:\n\(error.localizedDescription)"
        )
        interactor.handleErrorWithTask(error)
      }
      return EmptyView()
    }
  }
}
