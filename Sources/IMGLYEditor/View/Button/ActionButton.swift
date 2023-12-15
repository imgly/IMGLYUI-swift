import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct ActionButton: View {
  let action: Action

  init(_ action: Action) {
    self.action = action
  }

  @EnvironmentObject private var interactor: Interactor

  var body: some View {
    Button {
      interactor.actionButtonTapped(for: action)
    } label: {
      action.label
    }
  }
}
