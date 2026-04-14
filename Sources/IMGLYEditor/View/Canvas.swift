import IMGLYCamera
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYCore
import SwiftUI

struct Canvas: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.imglyIsPageNavigationEnabled) private var isPageNavigationEnabled: Bool
  @Environment(\.imglyInspectorBarEnabled) private var isInspectorBarEnabled
  @Environment(\.imglyBottomPanel) private var bottomPanel
  @Environment(\.imglyBottomPanelAnimation) private var bottomPanelAnimation

  let zoomPadding: CGFloat

  static let safeCoordinateSpaceName = "safeCanvas"
  static let safeCoordinateSpace = CoordinateSpace.named(safeCoordinateSpaceName)

  @Environment(\.verticalSizeClass) private var verticalSizeClass

  @Feature(.photosPickerMultiSelect) private var isPhotosPickerMultiSelectEnabled: Bool

  private let viewDebugging = false

  private var bottomBarHeight: CGFloat {
    let safeAreaInsetHeight: CGFloat = verticalSizeClass == .compact ? 33 : BottomBarLabelStyle.size.height
    let paddingTop: CGFloat = 8 + (barContentGeometry?.safeAreaInsets.top ?? 0)
    let paddingBottom: CGFloat = 22

    return safeAreaInsetHeight + paddingTop + paddingBottom
  }

  private var pageNavigationHeight: CGFloat {
    isPageNavigationEnabled && interactor.pageCount > 1 ? 32 : 0
  }

  private var isPageNavigationHidden: Bool {
    !isPageNavigationEnabled || interactor.selection?.blocks.isEmpty != nil || !interactor
      .isDefaultZoomLevel || interactor.pageCount < 2 || interactor.isPreviewMode || interactor.isPagesMode
  }

  @State private var barContentGeometry: Geometry?
  @State private var topSafeAreaInset: CGFloat = 0
  @State private var bottomSafeAreaInset: CGFloat = 0
  @State private var keyboardToolbarHeight: CGFloat = 0
  @State private var fullBottomPanelHeight: CGFloat = 0
  @State private var isBottomPanelAnimating = false
  @State private var isBottomPanelMinimized = false
  @State private var bottomPanelHeight: CGFloat = 0
  @State private var animatedSafeAreaInsetHeight: CGFloat = 0
  @State private var wasInTextMode = false
  @State private var hasCompletedInitialSetup = false
  @State private var wasSheetPresented = false

  private var safeAreaInsetHeight: CGFloat {
    // In text mode, the keyboard covers the bottom panel.
    // Use keyboard toolbar height for canvas safe area so the canvas
    // doesn't reserve space for the hidden-behind-keyboard bottom panel.
    if interactor.editMode == .text {
      return keyboardToolbarHeight
    }

    var height = bottomBarHeight + pageNavigationHeight

    let shouldUseMinimizedHeight = isBottomPanelMinimized
      || (interactor.sheet.isPresented
        && !interactor.sheet.isFloating
        && interactor.sheet.content != .voiceover
        && !interactor.sheet.isReplacing)

    height += shouldUseMinimizedHeight ? bottomPanelHeight : fullBottomPanelHeight
    return height
  }

  @ViewBuilder func bottomBar(content: SheetContent?) -> some View {
    BottomBar(content: content, id: id, height: bottomBarHeight, bottomSafeAreaInset: bottomSafeAreaInset)
  }

  @Environment(\.imglyCanvasMenuItems) private var canvasMenuItems
  @Environment(\.imglyAssetLibrary) private var anyAssetLibrary

  private var assetLibrary: some AssetLibrary {
    anyAssetLibrary ?? AnyAssetLibrary(erasing: DefaultAssetLibrary())
  }

  private var canvasMenuContext: CanvasMenu.Context? {
    guard let engine = interactor.engine, let id, engine.block.isValid(id) else {
      return nil
    }
    do {
      return try .init(engine: engine, eventHandler: interactor, assetLibrary: assetLibrary,
                       selection: .init(block: id, engine: engine))
    } catch {
      let error = EditorError(
        "Could not create CanvasMenu.Context.\nReason:\n\(error.localizedDescription)",
      )
      interactor.handleErrorWithTask(error)
      return nil
    }
  }

  private var inspectorBarContext: InspectorBar.Context? {
    // Use the current page as selection when in the page overview.
    let selectedBlockId = interactor.viewMode == .pages ? (try? interactor.engine?.getPage(interactor.page)) : id
    guard let engine = interactor.engine, let selectedBlockId, engine.block.isValid(selectedBlockId) else { return nil }

    do {
      return try .init(engine: engine, eventHandler: interactor, assetLibrary: assetLibrary,
                       selection: .init(block: selectedBlockId, engine: engine))
    } catch {
      let error = EditorError(
        "Could not create InspectorBar.Context.\nReason:\n\(error.localizedDescription)",
      )
      interactor.handleErrorWithTask(error)
      return nil
    }
  }

  private var bottomPanelContext: BottomPanel.Context? {
    guard let engine = interactor.engine else { return nil }
    return BottomPanel.Context(
      engine: engine,
      eventHandler: interactor,
      state: BottomPanel.State(
        isCreating: interactor.isCreating,
        isExporting: interactor.isExporting,
        viewMode: interactor.viewMode,
      ),
    )
  }

  @ViewBuilder var canvas: some View {
    ZStack {
      if viewDebugging {
        Color.red.opacity(0.2).border(.red).padding(5)
      }
      interactor.canvas
        .imgly.canvasAction(anchor: .top,
                            topSafeAreaInset: topSafeAreaInset,
                            bottomSafeAreaInset: animatedSafeAreaInsetHeight,
                            isVisible: !isBottomPanelAnimating) {
          if let canvasMenuItems, let canvasMenuContext {
            CanvasMenuView(items: canvasMenuItems, context: canvasMenuContext)
          }
        }
    }
  }

  @ViewBuilder var measureGeometry: some View {
    ZStack {
      if viewDebugging {
        Color.blue.opacity(0.2).border(.blue).allowsHitTesting(false)
      } else {
        Color.clear
      }
    }
    .coordinateSpace(name: Self.safeCoordinateSpaceName)
    .background {
      GeometryReader { safeCanvas in
        Color.clear
          .preference(key: CanvasGeometryKey.self, value: Geometry(safeCanvas, .local))
      }
    }
  }

  @ViewBuilder var inspectorBar: some View {
    if let content = interactor.sheetContentForBottomBar, let inspectorBarContext,
       let isInspectorBarEnabled = try? isInspectorBarEnabled(inspectorBarContext), isInspectorBarEnabled {
      Group {
        bottomBar(content: content)
          .zIndex(1)
          .transition(.move(edge: .bottom))
      }
      .animation(.easeInOut(duration: 0.2), value: interactor.sheetContentForBottomBar)
    }
  }

  var body: some View {
    VStack {
      ZStack {
        canvas
          .ignoresSafeArea()
        measureGeometry
      }
      .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: zoomPadding) }
      .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: zoomPadding) }
    }
    .onAppear {
      animatedSafeAreaInsetHeight = safeAreaInsetHeight
    }
    .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: zoomPadding) }
    .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: zoomPadding) }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if !interactor.isPreviewMode {
        ZStack {
          if viewDebugging {
            Color.green.opacity(0.2).border(.green).ignoresSafeArea()
          } else {
            Color.clear
          }
        }
        .modifier(HeightAnimationModifier(targetHeight: animatedSafeAreaInsetHeight))
        .transition(.move(edge: .bottom))
      }
    }
    .overlay {
      if !interactor.isCreating, interactor.isPagesMode {
        PageOverview()
          .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: bottomBarHeight) }
      }
    }
    .overlay(alignment: .bottom) {
      // Keep bottom panel visible during text editing (like Android).
      // The keyboard appears on top of it rather than replacing it.
      if !interactor.isCreating, let bottomPanel, let bottomPanelContext,
         let panel = try? bottomPanel(bottomPanelContext) {
        VStack(spacing: 0) {
          Spacer()
          AnyView(panel)
            .background {
              GeometryReader { geometry in
                let currentHeight = geometry.size.height
                Color.clear
                  .task {
                    if bottomPanelHeight == 0 {
                      fullBottomPanelHeight = currentHeight
                      bottomPanelHeight = currentHeight
                    }
                  }
                  .onChange(of: geometry.size.height) { newHeight in
                    // Save full height when no sheet is presented
                    if !interactor.sheet.isPresented, !isBottomPanelMinimized {
                      fullBottomPanelHeight = newHeight
                    }
                    bottomPanelHeight = newHeight
                  }
              }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: bottomBarHeight) }
        .onPreferenceChange(BottomPanelIsMinimizedKey.self) { newValue in
          isBottomPanelMinimized = newValue
        }
        .ignoresSafeArea(.keyboard)
      }
    }
    .overlay(alignment: .bottom) {
      VStack {
        Spacer()
        if !interactor.isCreating, !interactor.isPreviewMode {
          ZStack {
            bottomBar(content: nil)
              .disabled(interactor.sheet.isPresented)
              .onPreferenceChange(BottomBarContentGeometryKey.self) { newValue in
                barContentGeometry = newValue
              }
            inspectorBar
          }
          .transition(.move(edge: .bottom))
        }
      }
      .animation(.default, value: interactor.isPreviewMode)
      .ignoresSafeArea(.keyboard)
    }
    .overlay(alignment: .bottom) {
      if isPageNavigationEnabled {
        HStack(alignment: .top) {
          PageNavigation()
            .opacity(isPageNavigationHidden ? 0 : 1)
            .transition(.opacity)
        }
        .frame(height: pageNavigationHeight + 12)
        .animation(.linear(duration: 0.15), value: isPageNavigationHidden)
        .padding(.bottom, bottomBarHeight)
      }
    }
    .overlay(alignment: .bottom) {
      KeyboardToolbar()
        .onPreferenceChange(KeyboardToolbarSafeAreaInsetsKey.self) { newValue in
          if newValue?.top != 0 {
            keyboardToolbarHeight = newValue?.top ?? 0
          }
        }
    }
    .background {
      GeometryReader { geo in
        Color.clear
          .preference(key: CanvasSafeAreaInsetsKey.self, value: geo.safeAreaInsets)
      }
      .ignoresSafeArea(.keyboard)
    }
    .onPreferenceChange(CanvasSafeAreaInsetsKey.self) { newValue in
      topSafeAreaInset = newValue?.top ?? 0
      bottomSafeAreaInset = newValue?.bottom ?? 0
    }
    .onChange(of: verticalSizeClass) { newValue in
      interactor.verticalSizeClass = newValue
    }
    .onChange(of: safeAreaInsetHeight) { newValue in
      // Skip animation during initial setup
      if !hasCompletedInitialSetup {
        hasCompletedInitialSetup = true
        animatedSafeAreaInsetHeight = newValue
        return
      }

      // Check if we're entering or exiting text mode
      let isInTextMode = interactor.editMode == .text
      let isTextModeTransition = wasInTextMode != isInTextMode
      wasInTextMode = isInTextMode

      // Never animate when transitioning to/from text mode to avoid glitches
      // with keyboard appearance. The bottom panel stays visible but the
      // canvas safe area adjusts instantly.
      if isTextModeTransition || isInTextMode {
        animatedSafeAreaInsetHeight = newValue
        return
      }

      // Check if sheet presentation state is changing (opening or closing).
      // When sheet opens, the timeline hides. When sheet closes, the timeline returns.
      // In both cases, skip the canvas animation to avoid visual glitches.
      let isSheetPresented = interactor.sheet.isPresented
      let isSheetStateChanging = wasSheetPresented != isSheetPresented
      wasSheetPresented = isSheetPresented

      if isSheetStateChanging {
        animatedSafeAreaInsetHeight = newValue
        return
      }

      // Animate height changes when not in text mode (bottom panel minimize/expand)
      isBottomPanelAnimating = true
      if #available(iOS 17.0, *) {
        withAnimation(bottomPanelAnimation) {
          animatedSafeAreaInsetHeight = newValue
        } completion: {
          isBottomPanelAnimating = false
        }
      } else {
        withAnimation(bottomPanelAnimation) {
          animatedSafeAreaInsetHeight = newValue
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          isBottomPanelAnimating = false
        }
      }
    }
    .fullScreenCover(isPresented: $interactor.isCameraSheetShown) {
      Camera(interactor.config.settings) { result in
        interactor.isCameraSheetShown = false
        switch result {
        case let .success(.recording(recordings)):
          interactor.addCameraRecordings(recordings)
        case .success(.reaction):
          // Reaction case not handled here.
          break
        case let .failure(error):
          print(error)
        }
      }
    }
    .imgly.camera(isPresented: $interactor.isSystemCameraShown, media: media, onComplete: mediaCompletion)
    .imgly.photoRoll(isPresented: $interactor.isImagePickerShown, media: media,
                     maxSelectionCount: maxSelectionCount, onComplete: mediaCompletion)
    .imgly.photoRollImportOverlay(onError: interactor.handleError)
  }

  private var media: [MediaType] {
    let media: [MediaType] = interactor.sceneMode == .video ? [.image, .movie] : [.image]
    return media.filter {
      interactor.uploadAssetSourceIDs[$0] != nil
    }
  }

  private var maxSelectionCount: Int? {
    isPhotosPickerMultiSelectEnabled ? nil : 1
  }

  private var mediaCompletion: MediaCompletion {
    { result in
      do {
        let assets = try result.get()
        interactor.addAssetsFromImagePicker(assets)
      } catch {
        interactor.handleError(error)
      }
    }
  }
}

private struct CanvasSafeAreaInsetsKey: PreferenceKey {
  static let defaultValue: EdgeInsets? = nil
  static func reduce(value: inout EdgeInsets?, nextValue: () -> EdgeInsets?) {
    value = value ?? nextValue()
  }
}

@_spi(Internal) public struct BottomPanelIsMinimizedKey: PreferenceKey {
  @_spi(Internal) public static let defaultValue: Bool = false
  @_spi(Internal) public static func reduce(value: inout Bool, nextValue: () -> Bool) {
    value = nextValue()
  }
}

struct Canvas_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
