import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct BottomBar: View {
  let content: SheetContent?
  let id: Interactor.BlockID?
  let height: CGFloat
  let bottomSafeAreaInset: CGFloat

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  private let leadingPadding: CGFloat = 60

  private var isCloseButtonEnabled: Bool { content != .pageOverview }

  private var isRoot: Bool { content == nil }

  @ViewBuilder func button(_ mode: SheetMode) -> some View {
    Button {
      interactor.bottomBarButtonTapped(for: mode)
    } label: {
      mode.label(id, interactor)
    }
    .foregroundColor(mode == .delete ? .red : nil)
    .disabled(!isButtonEnabled(mode))
  }

  func isButtonEnabled(_ mode: SheetMode) -> Bool {
    switch mode {
    case .moveUp:
      if content == .pageOverview {
        interactor.canBringBackward(interactor.pageOverview.currentPage)
      } else {
        interactor.canBringForward(id)
      }
    case .moveDown:
      if content == .pageOverview {
        interactor.canBringForward(interactor.pageOverview.currentPage)
      } else {
        interactor.canBringBackward(id)
      }
    default:
      true
    }
  }

  func modes(for content: SheetContent?) -> [SheetMode] {
    guard content == .pageOverview else {
      return []
    }

    var modes: [SheetMode] = [.editPage, .addPage, .moveUp, .moveDown, .duplicate]
    if interactor.pageCount > 1 {
      modes += [.delete]
    }
    return modes.filter { interactor.isAllowed(interactor.pageOverview.currentPage, $0) }
  }

  @Environment(\.imglyInspectorBar) private var inspectorBar
  @Environment(\.imglyAssetLibrary) private var anyAssetLibrary

  private var assetLibrary: some AssetLibrary {
    anyAssetLibrary ?? AnyAssetLibrary(erasing: DefaultAssetLibrary())
  }

  private var inspectorBarContext: InspectorBar.Context? {
    guard let engine = interactor.engine, let id, engine.block.isValid(id) else {
      return nil
    }
    do {
      return try .init(engine: engine, eventHandler: interactor, assetLibrary: assetLibrary,
                       selection: .init(id: id, engine: engine))
    } catch {
      let error = EditorError(
        "Could not create InspectorBar.Context.\nReason:\n\(error.localizedDescription)"
      )
      interactor.handleErrorWithTask(error)
      return nil
    }
  }

  @State var bottomBarWidth: CGFloat?

  @ViewBuilder var barItems: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 0) {
        Group {
          if content != .pageOverview, let inspectorBar, let inspectorBarContext {
            InspectorBarView(inspectorBar: inspectorBar, context: inspectorBarContext)
              .symbolRenderingMode(.monochrome)
          } else {
            ForEach(modes(for: content)) {
              button($0)
            }
          }
        }
        .fixedSize()
        Spacer()
      }
      .buttonStyle(.bottomBar)
      .labelStyle(.bottomBar)
      .padding(.leading, isCloseButtonEnabled ? leadingPadding : nil)
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
            .frame(width: isCloseButtonEnabled ? leadingPadding : 0)
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
      if isCloseButtonEnabled {
        BottomBarCloseButton()
          .padding()
          .buttonStyle(.bottomBar)
      }
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
    .animation(nil, value: content)
  }

  @ViewBuilder var bottomBar: some View {
    ZStack {
      BottomToolbar {
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
