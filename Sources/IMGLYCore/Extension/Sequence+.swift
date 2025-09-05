import Foundation

extension Sequence where Element: Sendable {
  func concurrentMap<T: Sendable>(
    _ transform: @Sendable @escaping (Element) async throws -> T,
  ) async throws -> [T] {
    try await withThrowingTaskGroup(of: (Int, T).self) { group in
      for (index, element) in self.enumerated() {
        group.addTask {
          (index, try await transform(element))
        }
      }

      var results: [(Int, T)] = []

      for try await result in group {
        results.append(result)
      }

      return results
        .sorted { $0.0 < $1.0 }
        .map(\.1)
    }
  }
}
