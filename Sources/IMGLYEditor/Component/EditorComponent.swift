import IMGLYEngine
import SwiftUI
@_spi(Internal) import struct IMGLYCore.Error

// MARK: - EditorComponentID

public struct EditorComponentID: Hashable, Sendable {
  let value: String

  public init(_ value: String) {
    self.value = value
  }
}

extension EditorComponentID: ExpressibleByStringInterpolation {
  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}

// MARK: - EditorContext

/// An interface for the  context of ``EditorComponent``s.
public protocol EditorContext {
  /// The event handler of the current editor.
  var eventHandler: EditorEventHandler { get }
}

public extension EditorContext {
  typealias To<T> = @MainActor (_ context: Self) throws -> T
  typealias SendableTo<T> = @Sendable @MainActor (_ context: Self) throws -> T
}

// MARK: - EditorError

public struct EditorError: LocalizedError {
  public let errorDescription: String?

  public init(_ errorDescription: String) {
    self.errorDescription = errorDescription
  }
}

// MARK: - EditorComponent

public protocol EditorComponent {
  var id: EditorComponentID { get }

  associatedtype Context: EditorContext

  @MainActor
  func isVisible(_ context: Context) throws -> Bool

  associatedtype Body: View

  @MainActor @ViewBuilder
  func body(_ context: Context) throws -> Body
}

public extension EditorComponent {
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
