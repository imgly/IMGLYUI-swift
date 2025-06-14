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
            updateZoom(for: .sheetGeometryChanged, sheetGeometry: newValue)
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
        let zoom = interactor.zoomParameters(
          zoomPadding: zoomPadding,
          canvasGeometry: canvasGeometry,
          sheetGeometry: sheetGeometryIfPresented,
          layoutDirection: layoutDirection
        )
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

  private func updateZoom(for _: ZoomEvent, canvasGeometry: Geometry? = nil, sheetGeometry: Geometry? = nil) {
    let zoom = (
      zoomPadding,
      canvasGeometry ?? self.canvasGeometry,
      sheetGeometry ?? sheetGeometryIfPresented,
      layoutDirection
    )
    interactor.updateZoom(for: .sheetClosed, with: zoom)
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
