@_spi(Internal) import IMGLYCoreUI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

@_spi(Internal) public struct EditorUI: View {
  @EnvironmentObject private var interactor: Interactor

  @Environment(\.layoutDirection) private var layoutDirection
  @Environment(\.imglyInspectorBarItems) private var inspectorBarItems
  @Environment(\.imglyCanvasMenuItems) private var canvasMenuItems
  @Environment(\.colorScheme) private var colorScheme

  @_spi(Internal) public init(zoomPadding: CGFloat = 16) {
    self.zoomPadding = zoomPadding
  }

  @State private var canvasGeometry: Geometry?
  @State private var sheetGeometry: Geometry?
  private var sheetGeometryIfPresented: Geometry? { interactor.sheet.isPresented ? sheetGeometry : nil }
  private let zoomPadding: CGFloat

  private func zoomParameters(
    canvasGeometry: Geometry?,
    sheetGeometry: Geometry?
    // swiftlint:disable:next large_tuple
  ) -> (insets: EdgeInsets?, canvasHeight: CGFloat, padding: CGFloat) {
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
      return (rtl, canvasHeight, zoomPadding)
    }

    return (insets, canvasHeight, zoomPadding)
  }

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
        let zoom = zoomParameters(canvasGeometry: newValue, sheetGeometry: sheetGeometryIfPresented)
        interactor.updateZoom(for: .canvasGeometryChanged, with: zoom)
      }
      .onChange(of: interactor.page) { _ in
        let zoom = zoomParameters(canvasGeometry: canvasGeometry, sheetGeometry: sheetGeometryIfPresented)
        interactor.updateZoom(for: .pageChanged, with: zoom)
      }
      .onChange(of: interactor.isPagesMode) { newValue in
        if !newValue {
          // Force zoom to page when the page overview is closed to be sure that the right page is always shown.
          let zoom = zoomParameters(canvasGeometry: canvasGeometry, sheetGeometry: sheetGeometryIfPresented)
          interactor.updateZoom(for: .pageChanged, with: zoom)
        }
      }
      .onChange(of: interactor.textCursorPosition) { newValue in
        let zoom = zoomParameters(canvasGeometry: canvasGeometry, sheetGeometry: sheetGeometryIfPresented)
        interactor.updateZoom(for: .textCursorChanged(newValue), with: zoom)
      }
      .sheet(isPresented: $interactor.sheet.isPresented) {
        let zoom = zoomParameters(canvasGeometry: canvasGeometry, sheetGeometry: sheetGeometryIfPresented)
        interactor.updateZoom(for: .sheetClosed, with: zoom)
        // Reset sheet state to prevent memory leaks from retain cycles in view references
        interactor.sheet = SheetState()
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
          // We're setting the color scheme here because .preferredColorScheme inside 'Sheet'
          // is sometimes ignored on iOS 18
          .preferredColorScheme(colorScheme)
      }
      .imgly.errorAlert(isSheet: false)
      .modifier(ExportSheet(exportState: interactor.export))
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
      .imgly.inspectorBarItems { context in
        if let inspectorBarItems {
          try inspectorBarItems(context)
        } else {
          InspectorBar.Buttons.replace() // Video, Image, Sticker, Audio

          InspectorBar.Buttons.editText() // Text
          InspectorBar.Buttons.formatText() // Text
          InspectorBar.Buttons.fillStroke() // Page, Video, Image, Shape, Text
          InspectorBar.Buttons.textBackground() // Text
          InspectorBar.Buttons.editVoiceover() // Voiceover (video scenes only)
          InspectorBar.Buttons.volume() // Video, Audio, Voiceover (video scenes only)
          InspectorBar.Buttons.crop() // Video, Image

          InspectorBar.Buttons.adjustments() // Video, Image
          InspectorBar.Buttons.filter() // Video, Image
          InspectorBar.Buttons.effect() // Video, Image
          InspectorBar.Buttons.blur() // Video, Image
          InspectorBar.Buttons.shape() // Video, Image, Shape

          InspectorBar.Buttons.selectGroup() // Video, Image, Sticker, Shape, Text
          InspectorBar.Buttons.enterGroup() // Group

          InspectorBar.Buttons.layer() // Video, Image, Sticker, Shape, Text
          InspectorBar.Buttons.split() // Video, Image, Sticker, Shape, Text, Audio (video scenes only)
          InspectorBar.Buttons.moveAsClip() // Video, Image, Sticker, Shape, Text (video scenes only)
          InspectorBar.Buttons.moveAsOverlay() // Video, Image, Sticker, Shape, Text (video scenes only)
          InspectorBar.Buttons.reorder() // Video, Image, Sticker, Shape, Text (video scenes only)
          InspectorBar.Buttons.duplicate() // Video, Image, Sticker, Shape, Text, Audio
          InspectorBar.Buttons.delete() // Video, Image, Sticker, Shape, Text, Audio, Voiceover
        }
      }
      .imgly.canvasMenuItems { context in
        if let canvasMenuItems {
          try canvasMenuItems(context)
        } else {
          CanvasMenu.Buttons.selectGroup()
          CanvasMenu.Divider()
          CanvasMenu.Buttons.bringForward()
          CanvasMenu.Buttons.sendBackward()
          CanvasMenu.Divider()
          CanvasMenu.Buttons.duplicate()
          CanvasMenu.Buttons.delete()
        }
      }
      .modifier(NavigationBarView(items: navigationBarItems ?? { _ in [] }, context: navigationBarContext))
  }

  @Environment(\.imglyNavigationBarItems) private var navigationBarItems
  @Environment(\.imglyAssetLibrary) private var anyAssetLibrary

  private var assetLibrary: some AssetLibrary {
    anyAssetLibrary ?? AnyAssetLibrary(erasing: DefaultAssetLibrary())
  }

  private var navigationBarContext: NavigationBar.Context {
    .init(engine: interactor.engine,
          eventHandler: interactor,
          state: NavigationBar.State(
            isCreating: interactor.isCreating,
            isExporting: interactor.isExporting,
            viewMode: interactor.viewMode
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
