import SwiftUI

// MARK: - EditorComponentID

/// An identifier for ``EditorComponent``s.
/// - Note: Every unique ``EditorComponent`` must have a unique id suitable to be used with a SwiftUI `ForEach` view.
public struct EditorComponentID: Hashable, Sendable {
  let value: String
  let isUnique: Bool
  var uniqueID: Int?

  /// Creates an editor component identifier.
  /// - Parameter value: The value of the identifier.
  public init(_ value: String) {
    self.value = value
    isUnique = true
  }

  /// Creates an editor component identifier.
  /// - Parameters:
  ///   - value: The value of the identifier.
  ///   - isUnique: Whether the identifier is unique. `false` is currently only supported for ``CanvasMenu`` items.
  init(_ value: String, isUnique: Bool) {
    self.value = value
    self.isUnique = isUnique
  }
}

extension EditorComponentID: ExpressibleByStringInterpolation {
  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}

// MARK: - EditorContext

/// A type for the context of ``EditorComponent``s.
public protocol EditorContext {
  /// The event handler of the current editor.
  var eventHandler: EditorEventHandler { get }
}

public extension EditorContext {
  /// A closure that provides access to the context and returns a value.
  typealias To<T> = @MainActor (_ context: Self) throws -> T
  /// A sendable closure that provides access to the context and returns a value.
  typealias SendableTo<T> = @Sendable @MainActor (_ context: Self) throws -> T
}

// MARK: - EditorError

/// An error that occurred in the editor.
public struct EditorError: LocalizedError {
  public let errorDescription: String?

  /// Creates an editor error.
  /// - Parameter errorDescription: The description of the error.
  public init(_ errorDescription: String) {
    self.errorDescription = errorDescription
  }
}

// MARK: - EditorComponent

/// A type that represents a view component that can be used in the editor.
public protocol EditorComponent {
  /// The unique identifier of this component suitable to be used with a `ForEach` view.
  var id: EditorComponentID { get }

  /// The type of the context of this component.
  associatedtype Context: EditorContext

  /// The visibility of this component.
  /// - Parameter context: The context of this component.
  /// - Returns: `true` if this component should be visible.
  /// - Note: Prefer using this parameter to toggle the visibility instead of encoding it in the view returned by
  /// ``body(_:)``.
  @MainActor
  func isVisible(_ context: Context) throws -> Bool

  /// The type of view representing the `body` of this component.
  associatedtype Body: View

  /// The content and behavior of this component.
  /// - Parameter context: The context of this component.
  /// - Returns: The view representation of this component.
  /// - Note: Don't encode the visibility in this view. Use ``isVisible(_:)`` instead.
  @MainActor @ViewBuilder
  func body(_ context: Context) throws -> Body
}

public extension EditorComponent {
  /// The visibility of this component. By default, the component is always visible.
  /// - Returns: Always `true`.
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
