import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct RootBottomBar: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.colorScheme) private var colorScheme

  @State var rootBottomBarWidth: CGFloat?

  private let padding: CGFloat = 8

  @Environment(\.imglyEditorEnvironment) private var editorEnvironment

  private var assetLibrary: some AssetLibrary {
    let categories = AssetLibraryCategory.defaultCategories
    return AnyAssetLibrary(erasing: editorEnvironment.makeAssetLibrary(defaultCategories: categories))
  }

  private var dockItems: Dock.Items? {
    editorEnvironment.dockItems
  }

  private var dockContext: Dock.Context? {
    guard let engine = interactor.engine else {
      return nil
    }
    return .init(engine: engine, eventHandler: interactor, assetLibrary: assetLibrary)
  }

  private var dockAlignment: Alignment {
    guard let dockContext else { return .center }
    if let alignment = editorEnvironment.dockItemAlignment, let result = try? alignment(dockContext) {
      return result
    }
    return .center
  }

  private var dockScrollDisabled: Bool {
    guard let dockContext else { return false }
    if let scrollDisabled = editorEnvironment.dockScrollDisabled, let result = try? scrollDisabled(dockContext) {
      return result
    }
    return false
  }

  @ViewBuilder var content: some View {
    HStack(spacing: 0) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 0) {
          Group {
            if let dockItems, let dockContext {
              DockView(items: dockItems, context: dockContext)
                .symbolRenderingMode(.monochrome)
                .labelStyle(.bottomBar)
            }
          }
          .fixedSize()
        }
        .buttonStyle(.bottomBar)
        .padding(.horizontal, padding)
        .padding(.vertical, padding * 2)
        .frame(minWidth: rootBottomBarWidth, alignment: dockAlignment)
      }
      .scrollDisabled(dockScrollDisabled)
      .modifier(DisableScrollBounceIfSupported())
      .mask {
        // Mask the scroll view so that the fade-out gradients work on a blurred background material.
        Rectangle()
          .overlay {
            HStack {
              LinearGradient(
                gradient: Gradient(
                  colors: [.black, .clear],
                ),
                startPoint: UnitPoint(x: 0, y: 0.5),
                endPoint: .trailing,
              )
              .frame(width: padding)
              Spacer()
              LinearGradient(
                gradient: Gradient(
                  colors: [.clear, .black],
                ),
                startPoint: UnitPoint(x: 0.3, y: 0.5),
                endPoint: .trailing,
              )
              .frame(width: padding)
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

  @State private var isDockHidden = true

  private var dockBackgroundColor: Color {
    if let dockContext,
       let backgroundColor = editorEnvironment.dockBackgroundColor,
       let color = try? backgroundColor(dockContext, colorScheme) {
      return color
    }
    return colorScheme == .dark
      ? Color(uiColor: .systemBackground)
      : Color(uiColor: .secondarySystemBackground)
  }

  var body: some View {
    content
      .onPreferenceChange(DockHiddenKey.self) { newValue in
        isDockHidden = newValue
      }
      .background(alignment: .top) {
        if !isDockHidden {
          Rectangle()
            .fill(dockBackgroundColor)
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
