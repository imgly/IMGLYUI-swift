import Foundation

@_spi(Internal) public extension URLSession {
  // Silences warning: "Non-sendable type '(any URLSessionTaskDelegate)?' exiting main actor-isolated context in call to
  // non-isolated instance method 'data(from:delegate:)' cannot cross actor boundary"
  static let get: (URL) async throws -> (Data, URLResponse) = URLSession.shared.data
}
