import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct RootBottomBar: View {
  @EnvironmentObject private var interactor: Interactor

  private let fabSize: CGFloat = 56
  private let padding: CGFloat = 16

  @ViewBuilder var fab: some View {
    Button {
      interactor.bottomBarButtonTapped(for: .add)
    } label: {
      SheetMode.add.label
        .font(.title2)
        .labelStyle(.iconOnly)
        .frame(width: fabSize, height: fabSize)
    }
    .buttonStyle(.fab)
  }

  @ViewBuilder var divider: some View {
    Divider()
      .frame(height: 40)
      .overlay(.tertiary)
  }

  @ViewBuilder func button(_ item: RootBottomBarItem) -> some View {
    let mode = item.sheetMode
    Button {
      interactor.bottomBarButtonTapped(for: mode)
    } label: {
      mode.label(mode.pinnedBlockID, interactor)
    }
    .labelStyle(.bottomBar(alignment: mode == .selectionColors ? .leading : .center))
    .imgly.selection(mode.pinnedBlockID)
  }

  var showFAB: Bool {
    interactor.rootBottomBarItems.contains { $0 == .fab }
  }

  var items: [RootBottomBarItem] {
    interactor.rootBottomBarItems.filter {
      switch $0 {
      case .fab: return false
      case .selectionColors: return !interactor.selectionColors.isEmpty
      default: return true
      }
    }
  }

  @ViewBuilder var content: some View {
    VStack {
      Spacer()
      HStack(spacing: 16) {
        if showFAB {
          fab
        } else {
          Spacer()
        }
        if showFAB, !items.isEmpty {
          divider
        }
        HStack(spacing: 8) {
          ForEach(items) {
            button($0)
          }
          .fixedSize()
        }
        .buttonStyle(.bottomBar)
        Spacer()
      }
      .padding(padding)
    }
  }

  var body: some View {
    content
      .background(alignment: .bottom) {
        if !items.isEmpty {
          VisualEffect(effect: UIBlurEffect(style: .regular))
            .ignoresSafeArea()
            .frame(height: fabSize + 2 * padding)
        }
      }
  }
}

struct RootBottomBar_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
