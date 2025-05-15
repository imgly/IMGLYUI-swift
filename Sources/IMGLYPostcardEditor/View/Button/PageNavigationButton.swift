@_spi(Internal) import IMGLYEditor
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct PageNavigationButton: View {
  @EnvironmentObject private var interactor: Interactor

  let page: Page
  let direction: NavigationLabel.Direction

  init(to page: Page, direction: NavigationLabel.Direction) {
    self.page = page
    self.direction = direction
  }

  var body: some View {
    Button {
      interactor.actionButtonTapped(for: .page(page.index))
    } label: {
      NavigationLabel(page.localizedStringKey, direction: direction)
    }
    .disabled(interactor.isLoading)
  }
}
