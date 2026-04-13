@_spi(Internal) import IMGLYCoreUI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

@_spi(Internal) public struct EditorUI: View {
  @EnvironmentObject private var interactor: Interactor

  @Environment(\.layoutDirection) private var layoutDirection
  @Environment(\.imglyEditorEnvironment) private var editorEnvironment
  @Environment(\.colorScheme) private var colorScheme

  @State private var canvasGeometry: Geometry?
  @State private var sheetGeometry: Geometry?
  private var sheetGeometryIfPresented: Geometry? { interactor.sheet.isPresented ? sheetGeometry : nil }
  private var zoomPadding: CGFloat { editorEnvironment.zoomPadding ?? 0 }

  @State private var interactivePopGestureRecognizer: UIGestureRecognizer?

  @_spi(Internal) public var body: some View {
    Canvas(zoomPadding: zoomPadding)
      .background {
        Color(uiColor: .systemGroupedBackground)
          .ignoresSafeArea()
      }
      .allowsHitTesting(interactor.isCanvasHitTestingEnabled)
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(true)
      .introspect(.navigationStack, on: .iOS(.v16...), scope: .ancestor) { navigationController in
        // Delay mutation until the next runloop.
        // https://github.com/siteline/SwiftUI-Introspect/issues/212#issuecomment-1590130815
        DispatchQueue.main.async {
          // Disable swipe-back gesture and restore `onDisappear`
          interactivePopGestureRecognizer = navigationController.interactivePopGestureRecognizer
          interactivePopGestureRecognizer?.isEnabled = false
        }
      }
      .toolbarBackground(.visible, for: .navigationBar)
      .onPreferenceChange(CanvasGeometryKey.self) { newValue in
        canvasGeometry = newValue
      }
      .onChange(of: canvasGeometry) { newValue in
        updateZoom(for: .canvasGeometryChanged, canvasGeometry: newValue)
      }
      .onChange(of: interactor.page) { _ in
        updateZoom(for: .pageChanged)
      }
      .onChange(of: interactor.isPagesMode) { newValue in
        if !newValue {
          // Force zoom to page when the page overview is closed to be sure that the right page is always shown.
          updateZoom(for: .pageChanged)
        }
      }
      .onChange(of: interactor.textCursorPosition) { newValue in
        updateZoom(for: .textCursorChanged(newValue))
      }
      .sheet(isPresented: $interactor.sheet.isPresented) {
        updateZoom(for: .sheetClosed)
        interactor.onSheetDismissed()
      } content: {
        Sheet()
          .background {
            GeometryReader { geo in
              Color.clear
                .preference(key: SheetGeometryKey.self, value: Geometry(geo, Canvas.safeCoordinateSpace))
            }
          }
          .onPreferenceChange(SheetGeometryKey.self) { newValue in
            sheetGeometry = newValue
          }
          .onChange(of: sheetGeometry) { newValue in
            if newValue?.frame == .zero { return }
            updateZoom(for: .sheetGeometryChanged, sheetGeometry: newValue)
          }
          .imgly.errorAlert(isSheet: true)
          // We're setting color scheme and interactor environment object here inside sheet
          // because they are sometimes ignored on iOS 18
          .preferredColorScheme(colorScheme)
          .environmentObject(interactor)
      }
      .imgly.errorAlert(isSheet: false)
      .modifier(ExportSheet(exportState: interactor.export))
      .modifier(ShareSheet())
      .modifier(CloseConfirmationAlert())
      .onAppear {
        let zoom = interactor.zoomParameters(
          zoomPadding: zoomPadding,
          canvasGeometry: canvasGeometry,
          sheetGeometry: sheetGeometryIfPresented,
          layoutDirection: layoutDirection,
        )
        interactor.loadScene(with: zoom.insets)
      }
      .imgly.onWillDisappear {
        interactor.onWillDisappear()
      }
      .onDisappear {
        interactivePopGestureRecognizer?.isEnabled = true
      }
      .imgly.onDismiss {
        interactor.onDismiss()
      }
      .modifier(NavigationBarView(items: navigationBarItems ?? { @MainActor _ in [] }, context: navigationBarContext))
  }

  private func updateZoom(for event: ZoomEvent, canvasGeometry: Geometry? = nil, sheetGeometry: Geometry? = nil) {
    let zoom = (
      zoomPadding,
      canvasGeometry ?? self.canvasGeometry,
      sheetGeometry ?? sheetGeometryIfPresented,
      layoutDirection,
    )
    interactor.updateZoom(for: event, with: zoom)
  }

  private var navigationBarItems: NavigationBar.Items? {
    editorEnvironment.navigationBarItems
  }

  private var assetLibrary: some AssetLibrary {
    let categories = AssetLibraryCategory.defaultCategories
    return AnyAssetLibrary(erasing: editorEnvironment.makeAssetLibrary(defaultCategories: categories))
  }

  private var navigationBarContext: NavigationBar.Context {
    .init(engine: interactor.engine,
          eventHandler: interactor,
          state: NavigationBar.State(
            isCreating: interactor.isCreating,
            isExporting: interactor.isExporting,
            viewMode: interactor.viewMode,
          ),
          assetLibrary: assetLibrary)
  }
}

private struct SheetGeometryKey: PreferenceKey {
  static let defaultValue: Geometry? = nil
  static func reduce(value: inout Geometry?, nextValue: () -> Geometry?) {
    value = value ?? nextValue()
  }
}

struct EditorUI_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
