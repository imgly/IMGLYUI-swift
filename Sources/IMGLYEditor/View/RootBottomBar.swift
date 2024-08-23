import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct RootBottomBar: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.colorScheme) private var colorScheme

  @State var rootBottomBarWidth: CGFloat?

  private let fabSize: CGFloat = 56
  private let padding: CGFloat = 16

  @ViewBuilder var fab: some View {
    Button {
      interactor.bottomBarButtonTapped(for: .add)
    } label: {
      SheetMode.add.label
        .font(.title2)
        .fontWeight(.bold)
        .labelStyle(.iconOnly)
        .frame(width: fabSize, height: fabSize)
    }
    .buttonStyle(.fab)
    .padding(.horizontal, padding)
  }

  @ViewBuilder var divider: some View {
    Divider()
      .frame(height: 40)
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
      case .fab: false
      case .selectionColors: !interactor.selectionColors.isEmpty
      default: true
      }
    }
  }

  @ViewBuilder var content: some View {
    HStack(spacing: 0) {
      if showFAB {
        fab
      }
      if showFAB, !items.isEmpty {
        divider
      }
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: -2) {
          ForEach(items) {
            button($0)
          }
          .fixedSize()
        }
        .buttonStyle(.bottomBar)
        .padding(.horizontal, showFAB ? padding : padding / 2)
        .padding(.vertical, padding)
        .frame(minWidth: showFAB ? 0 : rootBottomBarWidth)
      }
      .modifier(DisableScrollBounceIfSupported())
      .mask {
        // Mask the scroll view so that the fade-out gradients work on a blurred background material.
        Rectangle()
          .overlay {
            HStack {
              LinearGradient(
                gradient: Gradient(
                  colors: [.black, .clear]
                ),
                startPoint: UnitPoint(x: 0, y: 0.5),
                endPoint: .trailing
              )
              .frame(width: showFAB ? padding : padding / 2)
              Spacer()
              LinearGradient(
                gradient: Gradient(
                  colors: [.clear, .black]
                ),
                startPoint: UnitPoint(x: 0.3, y: 0.5),
                endPoint: .trailing
              )
              .frame(width: showFAB ? padding : padding / 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .drawingGroup()
            .blendMode(.destinationOut)
          }
      }
      .background {
        GeometryReader { geo in
          Color.clear
            .preference(key: RootBottomBarWidthKey.self, value: geo.size.width)
        }
      }
      .onPreferenceChange(RootBottomBarWidthKey.self) { newValue in
        rootBottomBarWidth = newValue
      }
    }
  }

  var body: some View {
    content
      .background(alignment: .top) {
        if !items.isEmpty {
          Rectangle()
            .fill(colorScheme == .dark
              ? Color(uiColor: .systemBackground)
              : Color(uiColor: .secondarySystemBackground))
            .ignoresSafeArea()
        }
      }
  }
}

private struct RootBottomBarWidthKey: PreferenceKey {
  static let defaultValue: CGFloat? = nil
  static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    value = value ?? nextValue()
  }
}

private struct DisableScrollBounceIfSupported: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 16.4, *) {
      content
        .scrollBounceBehavior(.automatic)
    } else {
      content
    }
  }
}

struct RootBottomBar_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
