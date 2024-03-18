import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct BottomBar: View {
  let type: SheetType?
  let id: Interactor.BlockID?
  let height: CGFloat
  let bottomSafeAreaInset: CGFloat

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  @State private var leadingPadding: CGFloat = 60

  private var isRoot: Bool { type == nil }

  @ViewBuilder func button(_ mode: SheetMode) -> some View {
    Button {
      interactor.bottomBarButtonTapped(for: mode)
    } label: {
      mode.label(id, interactor)
    }
    .foregroundColor(mode == .delete ? .red : nil)
  }

  // swiftlint:disable:next cyclomatic_complexity
  func modes(for type: SheetType?) -> [SheetMode] {
    guard let type else {
      return []
    }

    let isVideo = interactor.sceneMode == .video

    var modes = [SheetMode]()
    if Set([.image, .video]).contains(type) {
      modes += [.adjustments, .filter, .effect, .blur]
    }
    if type == .text {
      modes += [.edit, .format]
    }
    if Set([.text, .shape, .page]).contains(type) {
      modes += [.fillAndStroke]
    }
    if type == .shape, Set([.line, .star, .polygon]).contains(interactor.shapeType(id)) {
      modes += [.options]
    }
    if isVideo, Set([.audio, .video]).contains(type) {
      modes += [.volume]
    }
    if Set([.image, .video]).contains(type) {
      modes += [.crop]
    }
    if !(type == .page && isVideo) {
      modes += [.duplicate]
    }
    if !Set([.page, .audio]).contains(type) {
      modes += [.layer]
    }
    if isVideo, Set([.text, .image, .shape, .sticker, .video, .audio]).contains(type) {
      modes += [.split]
    }
    if Set([.image, .video]).contains(type) {
      modes += [.fillAndStroke]
    }
    if isVideo, !Set([.page, .audio]).contains(type) {
      modes += [.attachToBackground, .detachFromBackground]
    }
    if isVideo, Set([.audio, .video]).contains(type) {
      modes += [.replace]
    }
    if Set([.image, .sticker]).contains(type) {
      modes += [.replace]
    }
    if isVideo, !Set([.page, .audio]).contains(type) {
      modes += [.reorder]
    }
    if type == .group {
      modes += [.enterGroup]
    }
    modes += [.selectGroup]
    if !(type == .page && isVideo) {
      modes += [.delete]
    }

    return modes.filter { mode in
      interactor.isAllowed(id, mode)
    }
  }

  @State var bottomBarWidth: CGFloat?

  @ViewBuilder var barItems: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 0) {
        ForEach(modes(for: type)) {
          button($0)
        }
        .fixedSize()
        Spacer()
      }
      .buttonStyle(.bottomBar)
      .labelStyle(.bottomBar)
      .padding(.leading, leadingPadding)
      .padding([.top, .bottom], 8)
      .frame(minWidth: bottomBarWidth)
      .animation(nil, value: bottomBarWidth)
    }
    .mask {
      // Mask the scroll view so that the fade-out gradients work on a blurred background material.
      Rectangle()
        .overlay {
          HStack {
            LinearGradient(
              gradient: Gradient(
                colors: [.black, .clear]
              ),
              startPoint: UnitPoint(x: 0.8, y: 0.5),
              endPoint: .trailing
            )
            .frame(width: 60)
            Spacer()
            LinearGradient(
              gradient: Gradient(
                colors: [.clear, .black]
              ),
              startPoint: UnitPoint(x: 0.3, y: 0.5),
              endPoint: .trailing
            )
            .frame(width: 30)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)

          .drawingGroup()
          .blendMode(.destinationOut)
        }
    }
    .overlay(alignment: .leading) {
      BottomBarCloseButton()
        .padding()
        .buttonStyle(.bottomBar)
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
          Rectangle()
            .fill(colorScheme == .dark
              ? Color(uiColor: .secondarySystemBackground)
              : Color(uiColor: .systemBackground))
            .ignoresSafeArea()
          barItems
        }
      }
      .background {
        // Apply shadow in background modifier to fix non-touchable bottom bar items
        // on iPhone 8 Plus, iPad Pro 9.7", and potentially other devices.
        Rectangle()
          .inset(by: 1)
          .shadow(color: .black.opacity(0.15), radius: 7, y: 2)
      }
      .opacity(isRoot ? 0 : 1)
      if isRoot {
        RootBottomBar()
      }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      Color.clear // Fix abrupt view (dis)appearance in safe area during transitions.
        .frame(height: max(0, bottomSafeAreaInset))
      bottomBar
        .frame(height: height)
    }
    .disabled(interactor.isLoading || interactor.sheet.isPresented)
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
