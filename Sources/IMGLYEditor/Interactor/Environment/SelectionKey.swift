import SwiftUI

private struct SelectionKey: EnvironmentKey {
  static let defaultValue: Interactor.BlockID? = nil
}

extension EnvironmentValues {
  var imglySelection: Interactor.BlockID? {
    get { self[SelectionKey.self] }
    set { self[SelectionKey.self] = newValue }
  }
}
