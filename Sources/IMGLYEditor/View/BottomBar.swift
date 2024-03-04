import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct BottomBar: View {
  let type: SheetType?
  let id: Interactor.BlockID?
  let height: CGFloat
  let bottomSafeAreaInset: CGFloat

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.imglyIsPageNavigationEnabled) private var isPageNavigationEnabled: Bool

  private var isRoot: Bool { type == nil }

  @ViewBuilder func button(_ mode: SheetMode) -> some View {
    Button {
      interactor.bottomBarButtonTapped(for: mode)
    } label: {
      mode.label(id, interactor)
    }
  }

  func modes(for type: SheetType?) -> [SheetMode] {
    guard let type else {
      return []
    }
    var modes = [SheetMode]()

    if Set([.image, .sticker]).contains(type) {
      modes += [.replace]
    }
    if type == .text {
      modes += [.edit, .format]
    }
    if type == .image {
      modes += [.crop]
    }
    if type == .shape, Set([.line, .star, .polygon]).contains(interactor.shapeType(id)) {
      modes += [.options]
    }
    if Set([.text, .image, .shape, .page]).contains(type) {
      modes += [.fillAndStroke]
    }
    if type == .image {
      modes += [.adjustments, .filter, .effect, .blur]
    }
    if type != .page {
      modes += [.layer]
    }
    if type == .group {
      modes += [.enterGroup]
    }
    modes += [.selectGroup]

    return modes.filter { mode in
      interactor.isAllowed(id, mode)
    }
  }

  @State var bottomBarWidth: CGFloat?

  @ViewBuilder var barItems: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(modes(for: type)) {
          button($0)
        }
        .fixedSize()
      }
      .buttonStyle(.bottomBar)
      .labelStyle(.bottomBar)
      .padding([.leading, .trailing], 8)
      .padding([.top, .bottom], 8)
      .frame(minWidth: bottomBarWidth)
      .animation(nil, value: bottomBarWidth)
    }
    .background {
      GeometryReader { geo in
        Color.clear
          .preference(key: BottomBarWidthKey.self, value: geo.size.width)
      }
    }
    .onPreferenceChange(BottomBarWidthKey.self) { newValue in
      bottomBarWidth = newValue
    }
    .animation(nil, value: type)
  }

  @ViewBuilder var bottomBar: some View {
    ZStack {
      BottomToolbar(title: Text(type?.localizedStringKey ?? "")) {
        ZStack {
          Color(uiColor: .secondarySystemBackground)
            .ignoresSafeArea()
          barItems
        }
      }
      .background {
        // Apply shadow in background modifier to fix non-touchable bottom bar items
        // on iPhone 8 Plus, iPad Pro 9.7", and potentially other devices.
        Rectangle()
          .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
      }
      .opacity(isRoot ? 0 : 1)
      if isRoot {
        RootBottomBar()
      }
    }
  }

  var body: some View {
    let heightWithPageControl = (isRoot && verticalSizeClass == .compact && isPageNavigationEnabled) ? height + 16 :
      height
    VStack(spacing: 0) {
      Color.clear // Fix abrupt view (dis)appearance in safe area during transitions.
        .frame(height: bottomSafeAreaInset)
      bottomBar
        .frame(height: heightWithPageControl)
    }
    .disabled(interactor.isLoading)
    .imgly.selection(id)
  }
}

private struct BottomBarWidthKey: PreferenceKey {
  static let defaultValue: CGFloat? = nil
  static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    value = value ?? nextValue()
  }
}

struct BottomBar_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
