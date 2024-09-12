import SwiftUI

struct CanvasMenu: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @State var pageIndex = 0

  var pages: [[Action]] {
    let pages: [[Action]] = [[.duplicate, .delete], [.up, .down]]

    return pages.compactMap { actions in
      let page = actions.filter { interactor.isAllowed(id, $0) }
      return page.isEmpty ? nil : page
    }
  }

  func isDisabled(_ action: Action) -> Bool {
    switch action {
    case .toTop, .up:
      !interactor.canBringForward(id)
    case .toBottom, .down:
      !interactor.canBringBackward(id)
    default:
      false
    }
  }

  @ViewBuilder func button(_ action: Action) -> some View {
    ActionButton(action)
      .frame(width: 48, height: 38)
      .disabled(isDisabled(action))
  }

  @ViewBuilder var divider: some View {
    Divider()
      .overlay(.tertiary)
  }

  @ViewBuilder var previousPage: some View {
    Button {
      pageIndex -= 1
    } label: {
      Label("Previous Menu Page", systemImage: "chevron.backward")
    }
    .frame(width: 32)
  }

  @ViewBuilder var nextPage: some View {
    Button {
      pageIndex += 1
    } label: {
      Label("Next Menu Page", systemImage: "chevron.forward")
    }
    .frame(width: 32)
  }

  @ViewBuilder var menu: some View {
    let pages = pages

    if (0 ..< pages.count).contains(pageIndex) {
      HStack(spacing: 0) {
        if pages.count > 1, pageIndex != pages.startIndex {
          previousPage
          divider
        }

        let page = pages[pageIndex]
        if let last = page.last {
          if page.count > 1 {
            ForEach(page.dropLast()) {
              button($0)
              divider
            }
          }
          button(last)
        }

        if pages.count > 1, pageIndex != pages.endIndex - 1 {
          divider
          nextPage
        }
      }
      .labelStyle(.iconOnly)
      .background(
        RoundedRectangle(cornerRadius: 8).fill(.bar)
          .shadow(color: .black.opacity(0.2), radius: 10)
      )
    }
  }

  @State private var size: CGSize?

  private var halfHeight: CGFloat { (size?.height ?? 0) / 2 }

  var body: some View {
    menu
      .fixedSize()
      .background {
        GeometryReader { geo in
          Color.clear
            .preference(key: CanvasMenuSizeKey.self, value: geo.size)
        }
      }
      .onPreferenceChange(CanvasMenuSizeKey.self) { newValue in
        size = newValue
      }
      .offset(y: -halfHeight - 24)
      .onChange(of: id) { _ in
        pageIndex = 0
      }
  }
}

private struct CanvasMenuSizeKey: PreferenceKey {
  static let defaultValue: CGSize? = nil
  static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
    value = value ?? nextValue()
  }
}

struct CanvasMenu_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
