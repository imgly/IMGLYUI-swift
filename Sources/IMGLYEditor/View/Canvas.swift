import IMGLYCamera
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct Canvas: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.imglyIsPageNavigationEnabled) private var isPageNavigationEnabled: Bool

  let zoomPadding: CGFloat

  static let safeCoordinateSpaceName = "safeCanvas"
  static let safeCoordinateSpace = CoordinateSpace.named(safeCoordinateSpaceName)

  @Environment(\.verticalSizeClass) private var verticalSizeClass

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

  private var dynamicTimelineHeight: CGFloat {
    let configuration = interactor.timelineProperties.configuration
    let trackHeight = configuration.trackHeight
    let backgroundTrackHeight = interactor.timelineProperties.configuration.backgroundTrackHeight
    let trackSpacing = configuration.trackSpacing
    let tracksCount = CGFloat(interactor.timelineProperties.dataSource.tracks.count)
    let rulerHeight = configuration.timelineRulerHeight

    // Show at least one foreground track, even if it’s empty.
    let tracksHeight = max(1, tracksCount + 1) * (trackHeight + trackSpacing) + backgroundTrackHeight
    let totalHeight = timelinePlayerBarHeight + tracksHeight + rulerHeight + trackSpacing * 3

    // Limit timeline height
    let clampedHeight = min(260, totalHeight)
    return clampedHeight
  }

  private let timelinePlayerBarHeight: CGFloat = 56

  private var safeAreaInsetHeight: CGFloat {
    if interactor.editMode != .text {
      var height = bottomBarHeight + pageNavigationHeight
      if interactor.sceneMode == .video {
        if isTimelineMinimized || (interactor.sheet.isPresented
          && !interactor.sheet.isFloating
          && interactor.sheet.mode != .addVoiceOver
          && interactor.sheet.mode != .replace) {
          height += timelinePlayerBarHeight
        } else {
          height += dynamicTimelineHeight
        }
      }
      return height
    } else {
      return keyboardToolbarHeight
    }
  }

  private var isPageNavigationHidden: Bool {
    !isPageNavigationEnabled || interactor.selection?.blocks.isEmpty != nil || !interactor
      .isDefaultZoomLevel || interactor.pageCount < 2 || !interactor.isEditing || interactor.isPageOverviewShown
  }

  @State private var barContentGeometry: Geometry?
  @State private var topSafeAreaInset: CGFloat = 0
  @State private var bottomSafeAreaInset: CGFloat = 0
  @State private var keyboardToolbarHeight: CGFloat = 0
  @State private var isTimelineMinimized = false
  @State private var isTimelineAnimating = false

  @ViewBuilder func bottomBar(type: InternalSheetType?) -> some View {
    BottomBar(type: type, id: id, height: bottomBarHeight, bottomSafeAreaInset: bottomSafeAreaInset)
  }

  @ViewBuilder var canvas: some View {
    ZStack {
      if viewDebugging {
        Color.red.opacity(0.2).border(.red).padding(5)
      }
      interactor.canvas
        .imgly.canvasAction(anchor: .top,
                            topSafeAreaInset: topSafeAreaInset,
                            bottomSafeAreaInset: safeAreaInsetHeight,
                            isVisible: !isTimelineAnimating) {
          CanvasMenu()
        }
    }
  }

  @ViewBuilder func playerBar() -> some View {
    if let timeline = interactor.timelineProperties.timeline {
      PlayerBarView(isTimelineMinimized: $isTimelineMinimized,
                    isTimelineAnimating: $isTimelineAnimating)
        .environmentObject(AnyTimelineInteractor(erasing: interactor))
        .environmentObject(interactor.timelineProperties.player)
        .environmentObject(timeline)
    }
  }

  @ViewBuilder func timeline() -> some View {
    TimelineView()
      .environmentObject(AnyTimelineInteractor(erasing: interactor))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: zoomPadding) }
    .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: zoomPadding) }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if interactor.isEditing {
        ZStack {
          if viewDebugging {
            Color.green.opacity(0.2).border(.green).ignoresSafeArea()
          } else {
            Color.clear
          }
        }
        .modifier(HeightAnimationModifier(targetHeight: safeAreaInsetHeight))
        .transition(.move(edge: .bottom))
      }
    }
    .overlay {
      if !interactor.isLoading, interactor.isPageOverviewShown {
        PageOverview()
          .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: bottomBarHeight) }
      }
    }
    .overlay(alignment: .bottom) {
      if !interactor.isLoading, interactor.sceneMode == .video, interactor.editMode != .text {
        VStack(spacing: 0) {
          VStack(spacing: 0) {
            playerBar()
              .frame(height: timelinePlayerBarHeight)
            if !isTimelineMinimized,
               !interactor.sheet.isPresented || interactor.sheet.isFloating || interactor.sheet.mode == .replace {
              timeline()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
          }
          .background {
            Rectangle()
              .fill(colorScheme == .dark
                ? Color(uiColor: .systemBackground)
                : Color(uiColor: .secondarySystemBackground))
          }
          .frame(maxHeight: isTimelineMinimized || (interactor.sheet.isPresented
              && !interactor.sheet.isFloating
              && interactor.sheet.mode != .replace)
            ? timelinePlayerBarHeight
            : dynamicTimelineHeight)
          .animation(.imgly.timelineMinimizeMaximize, value: interactor.sheet.isPresented)
        }
        .overlay(alignment: .bottom) {
          // Line between player bar and bottom bar when timeline is collapsed
          Group {
            if isTimelineMinimized, interactor.selection == nil {
              Divider()
                .transition(.opacity)
            }
          }
          .animation(.linear, value: interactor.selection)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: bottomBarHeight) }
      }
    }
    .overlay(alignment: .bottom) {
      VStack {
        Spacer()
        if !interactor.isLoading, interactor.isEditing {
          ZStack {
            bottomBar(type: nil)
              .disabled(interactor.sheet.isPresented)
              .onPreferenceChange(BottomBarContentGeometryKey.self) { newValue in
                barContentGeometry = newValue
              }
            Group {
              if let type = interactor.sheetTypeForBottomBar {
                bottomBar(type: type)
                  .zIndex(1)
                  .transition(.move(edge: .bottom))
              }
            }
            .animation(.easeInOut(duration: 0.2), value: interactor.sheetTypeForBottomBar)
          }
          .transition(.move(edge: .bottom))
        }
      }
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

      isTimelineMinimized = true
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
    .imgly.photoRoll(isPresented: $interactor.isImagePickerShown, media: media, onComplete: mediaCompletion)
  }

  private var media: [MediaType] {
    let media: [MediaType] = interactor.sceneMode == .video ? [.image, .movie] : [.image]
    return media.filter {
      interactor.uploadAssetSourceIDs[$0] != nil
    }
  }

  private var mediaCompletion: MediaCompletion {
    { result in
      do {
        let (url, mediaType) = try result.get()
        interactor.addAssetFromImagePicker(url: url, mediaType: mediaType)
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

struct Canvas_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
