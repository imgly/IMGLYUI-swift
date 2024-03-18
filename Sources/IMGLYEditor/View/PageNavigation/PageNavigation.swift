import SwiftUI

private struct PageNavigationEnabledKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

extension EnvironmentValues {
  var imglyIsPageNavigationEnabled: Bool {
    get { self[PageNavigationEnabledKey.self] }
    set { self[PageNavigationEnabledKey.self] = newValue }
  }
}

struct PageNavigationLabel: View {
  let title: LocalizedStringKey
  let direction: NavigationLabel.Direction

  var body: some View {
    Label(title, systemImage: direction.rawValue)
      .symbolVariant(.circle)
      .font(.title3)
      .tint(Color(UIColor.label))
      .padding(20)
      .contentShape(Rectangle())
  }
}

struct PageNavigation: View {
  @EnvironmentObject private var interactor: Interactor

  private var isFirstPage: Bool {
    interactor.page == 0
  }

  private var isLastPage: Bool {
    interactor.page == interactor.pageCount - 1
  }

  var body: some View {
    let page: Binding<Int> = .init {
      interactor.page
    } set: { newValue in
      interactor.actionButtonTapped(for: .page(newValue))
    }

    HStack {
      Button {
        interactor.actionButtonTapped(for: .page(interactor.page - 1))
      } label: {
        PageNavigationLabel(title: "Previous Page", direction: .backward)
      }
      .disabled(isFirstPage)

      PageControl(currentPage: page, numberOfPages: interactor.pageCount)

      Button {
        interactor.actionButtonTapped(for: .page(interactor.page + 1))
      } label: {
        PageNavigationLabel(title: "Next Page", direction: .forward)
      }
      .disabled(isLastPage)
    }
    .labelStyle(.iconOnly)
  }
}
