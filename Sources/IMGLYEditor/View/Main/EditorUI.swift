@_spi(Internal) import IMGLYCoreUI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

@_spi(Internal) public struct EditorUI: View {
  @EnvironmentObject private var interactor: Interactor

  @Environment(\.layoutDirection) private var layoutDirection

  @_spi(Internal) public init(zoomPadding: CGFloat = 16) {
    self.zoomPadding = zoomPadding
  }

  @State private var canvasGeometry: Geometry?
  @State private var sheetGeometry: Geometry?
  private var sheetGeometryIfPresented: Geometry? { interactor.sheet.isPresented ? sheetGeometry : nil }
  private let zoomPadding: CGFloat

  private func zoomParameters(canvasGeometry: Geometry?,
                              sheetGeometry: Geometry?) -> (insets: EdgeInsets?, canvasHeight: CGFloat) {
    let canvasHeight = canvasGeometry?.size.height ?? 0

    let insets: EdgeInsets?
    if let sheetGeometry, let canvasGeometry {
      var sheetInsets = canvasGeometry.safeAreaInsets
      let height = canvasGeometry.size.height
      let sheetMinY = sheetGeometry.frame.minY - sheetGeometry.safeAreaInsets.top
      sheetInsets.bottom = max(sheetInsets.bottom, zoomPadding + height - sheetMinY)
      sheetInsets.bottom = min(sheetInsets.bottom, height * 0.7)
      insets = sheetInsets
    } else {
      insets = canvasGeometry?.safeAreaInsets
    }

    if var rtl = insets, layoutDirection == .rightToLeft {
      swap(&rtl.leading, &rtl.trailing)
      return (rtl, canvasHeight)
    }

    return (insets, canvasHeight)
  }

  @State private var interactivePopGestureRecognizer: UIGestureRecognizer?

  var isBackButtonHidden: Bool { !interactor.isEditing }

  @_spi(Internal) public var body: some View {
    Canvas(zoomPadding: zoomPadding)
      .background {
        Color(uiColor: .systemGroupedBackground)
          .ignoresSafeArea()
      }
      .allowsHitTesting(interactor.isCanvasHitTestingEnabled)
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(isBackButtonHidden)
      .preference(key: BackButtonHiddenKey.self, value: isBackButtonHidden)
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
        let zoom = zoomParameters(canvasGeometry: newValue, sheetGeometry: sheetGeometryIfPresented)
        interactor.updateZoom(for: .canvasGeometryChanged, with: zoom)
      }
      .onChange(of: interactor.page) { _ in
        let zoom = zoomParameters(canvasGeometry: canvasGeometry, sheetGeometry: sheetGeometryIfPresented)
        interactor.updateZoom(for: .pageChanged, with: zoom)
      }
      .onChange(of: interactor.textCursorPosition) { newValue in
        let zoom = zoomParameters(canvasGeometry: canvasGeometry, sheetGeometry: sheetGeometryIfPresented)
        interactor.updateZoom(for: .textCursorChanged(newValue), with: zoom)
      }
      .sheet(isPresented: $interactor.sheet.isPresented) {
        let zoom = zoomParameters(canvasGeometry: canvasGeometry, sheetGeometry: sheetGeometryIfPresented)
        interactor.updateZoom(for: .sheetClosed, with: zoom)
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
            let zoom = zoomParameters(canvasGeometry: canvasGeometry, sheetGeometry: newValue)
            interactor.updateZoom(for: .sheetGeometryChanged, with: zoom)
          }
          .imgly.errorAlert(isSheet: true)
      }
      .imgly.errorAlert(isSheet: false)
      .modifier(ExportSheet())
      .modifier(ShareSheet())
      .onAppear {
        let zoom = zoomParameters(canvasGeometry: canvasGeometry, sheetGeometry: sheetGeometryIfPresented)
        interactor.loadScene(with: zoom.insets)
      }
      .imgly.onWillDisappear {
        interactor.onWillDisappear()
      }
      .onDisappear {
        interactor.onDisappear()
        interactivePopGestureRecognizer?.isEnabled = true
      }
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
