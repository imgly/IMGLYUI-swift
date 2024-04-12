import Foundation

@_spi(Internal) public extension URLSession {
  // https://forums.developer.apple.com/forums/thread/727823
  // Silences warning: "Non-sendable type '(any URLSessionTaskDelegate)?' exiting main actor-isolated context in call to
  // non-isolated instance method 'data(from:delegate:)' cannot cross actor boundary"
  nonisolated func get(_ url: URL) async throws -> (Data, URLResponse) {
    try await data(from: url)
  }
}
