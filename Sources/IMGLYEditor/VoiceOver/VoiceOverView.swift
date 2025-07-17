import CoreMedia
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

struct VoiceOverView<ViewModel: VoiceOverViewModelProtocol>: View {
  // MARK: - Constants

  private enum Localization {
    static var buttonCancel: LocalizedStringKey { "Cancel" }
    static var buttonDone: LocalizedStringKey { "Done" }
    static var playButton: LocalizedStringKey { "Play Voiceover" }
    static var muteButton: LocalizedStringKey { "Mute other Audio" }
    static var unmuteButton: LocalizedStringKey { "Unmute Other Audio" }
    static var labelStartRecording: LocalizedStringKey { "Start recording" }
    static var buttonDontAllow: LocalizedStringKey { "Don’t Allow" }
    static var buttonSettings: LocalizedStringKey { "Settings" }
    static var buttonDeleteVoiceover: LocalizedStringKey { "Delete Voiceover" }
    static var buttonDiscardVoiceover: LocalizedStringKey { "Discard Changes" }
    static var confirmationCancelMessage: LocalizedStringKey {
      "Your recording will be discarded. This cannot be undone."
    }

    static var confirmationEditCancelMessage: LocalizedStringKey {
      "Your changes will be discarded. This cannot be undone."
    }
  }

  private enum Images {
    static var systemPlayButton: String { "play" }
    static var systemMuteButton: String { "speaker.wave.2" }
    static var systemUnmuteButton: String { "speaker.slash" }
    static var systemStartRecord: String { "mic.badge.plus" }
    static var systemPause: String { "pause" }
  }

  private enum Colors {
    static var timeIndicator: Color { Color.pink }
  }

  // MARK: Properties

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var player: Player
  @EnvironmentObject var interactor: Interactor

  @ObservedObject private var viewModel: ViewModel
  @State private var latestUpdatedPositions: [Wave] = []

  // Scroll Behavior
  @State private var horizontalScrollView: UIScrollView?
  @StateObject private var horizontalScrollViewDelegate = TimelineScrollViewDelegate()
  @State private var isShowingCancelAlert: Bool = false
  @State private var isLoading = true
  @State private var identifiableError: ErrorAlertModifier.IdentifiableError?

  // MARK: - Initializers

  init(viewModel: ViewModel) {
    self.viewModel = viewModel
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 6) {
      timerLabelView()
      content
      controlButtons
    }
    .imgly.loadingOverlay(isLoading: viewModel.state == .loading)
    .toolbar { toolbarContent }
    .alert(Text(verbatim: CamMicUsageDescriptionFromBundleHelper.shared.microphoneAlertHeadline),
           isPresented: $viewModel.isShowingPermissionsAlertForMicrophone) {
      Button(Localization.buttonDontAllow, role: .cancel) {}
      Button(Localization.buttonSettings) { AppSettingsHelper.openAppSettings() }
    } message: {
      Text(verbatim: CamMicUsageDescriptionFromBundleHelper.shared.microphoneUsageDescription)
    }
    .errorAlert(error: $identifiableError)
    .onChange(of: viewModel.state) { newState in
      if case let .error(message) = newState {
        identifiableError = ErrorAlertModifier.IdentifiableError(message)
      } else if newState == .ended {
        interactor.sheetDismissButtonTapped()
      }
    }
  }

  // MARK: - UI Components

  // MARK: Toolbar

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) { leadingToolbarItem }
    ToolbarItem(placement: .navigationBarTrailing) { trailingToolbarItem }
  }

  private var leadingToolbarItem: some View {
    Button(Localization.buttonCancel) {
      viewModel.pauseAnyActivity()
      if viewModel.alreadyRecordedAudio {
        isShowingCancelAlert = true
      } else {
        viewModel.cancelAction()
      }
    }
    .confirmationDialog(
      viewModel.mode == .new ? Localization.confirmationCancelMessage : Localization.confirmationEditCancelMessage,
      isPresented: $isShowingCancelAlert,
      titleVisibility: .visible
    ) {
      Button(
        viewModel.mode == .new ? Localization.buttonDeleteVoiceover : Localization.buttonDiscardVoiceover,
        role: .destructive
      ) {
        viewModel.cancelAction()
      }
      Button(Localization.buttonCancel, role: .cancel) {}
    }
    .tint(.blue)
    .buttonStyle(.borderless)
  }

  private var trailingToolbarItem: some View {
    Button(Localization.buttonDone) {
      viewModel.doneAction()
    }
    .tint(.blue)
    .fontWeight(.semibold)
    .buttonStyle(.bordered)
    .buttonBorderShape(.capsule)
  }

  // MARK: Bottom Buttons

  private var controlButtons: some View {
    HStack(alignment: .bottom) {
      playButton
      Spacer()
      AudioRecordButton(action: {
                          Task { await viewModel.toggleAction() }
                        },
                        state: viewModel.recordingButtonState,
                        isEnabled: viewModel.isRecordingEnabled && !horizontalScrollViewDelegate.isDecelerating)
      Spacer()
      muteButton
    }
    .padding(.bottom, 42)
  }

  private var muteButton: some View {
    Button(action: {
      viewModel.toggleExternalAudio()
    }, label: {
      Label {
        Text(viewModel.isSoundMuted ? Localization.unmuteButton : Localization.muteButton)
      } icon: {
        Image(systemName: viewModel.isSoundMuted ? Images.systemUnmuteButton : Images.systemMuteButton)
      }
    })
    .buttonStyle(.bottomBar)
    .labelStyle(.bottomBar)
  }

  private var playButton: some View {
    Button(action: {
      viewModel.togglePlay()
    }, label: {
      Label {
        Text(Localization.playButton)
      } icon: {
        Image(systemName: viewModel.state == .playing ? Images.systemPause : Images.systemPlayButton)
      }
    })
    .disabled(!viewModel.isPlayingEnabled)
    .buttonStyle(.bottomBar)
    .labelStyle(.bottomBar)
  }

  // MARK: Timeline

  private var content: some View {
    GeometryReader { geometry in
      ScrollView(.horizontal, showsIndicators: false) {
        wavesViewContainer(height: geometry.size.height - configuration.timelineRulerHeight,
                           width: geometry.size.width)
          .overlay(timeRulerView(width: geometry.size.width).offset(y: -3), alignment: .topLeading)
          .padding(.vertical, 3)
      }
      .overlay(timeIndicatorOverlay, alignment: .center)
      .overlay(!viewModel.audioWaves.isEmpty ? nil :
        recordingStarterPlaceholer(width: geometry.size.width), alignment: .center)
      .disabled(viewModel.state == .recording || viewModel.state == .playing)
      .introspect(.scrollView, on: .iOS(.v16...)) { horizontalScrollView in
        setupHorizontalScrollView(horizontalScrollView)
      }
      .onChange(of: player.playheadPosition) { _ in
        guard !horizontalScrollViewDelegate.isDraggingOrDecelerating else { return }
        updateHorizontalOffset()
      }
      .onChange(of: horizontalScrollViewDelegate.contentOffset) { newValue in
        handleScrollViewContentOffsetChange(newValue)
      }
    }
  }

  @ViewBuilder
  private func wavesViewContainer(height: CGFloat, width: CGFloat) -> some View {
    let timelineWidth = timeline.totalWidth
    HStack(spacing: 0) {
      wavesView
        .frame(width: timelineWidth, height: height)
        .background(Color(uiColor: .secondarySystemBackground))
        .padding(.top, configuration.timelineRulerHeight)
        .clipped()
    }
    .frame(width: timelineWidth + width)
  }

  @ViewBuilder
  private var wavesView: some View {
    GeometryReader { geometry in
      let lineHeight = geometry.size.height
      ForEach(viewModel.audioWaves.keys.sorted(), id: \.self) { key in
        if let wave = viewModel.audioWaves[key] {
          WaveView(wave: wave, maxHeight: lineHeight)
        }
      }
    }
  }

  private func timeRulerView(width: CGFloat) -> some View {
    VoiceOverTimeRuler(viewportWidth: width)
      .frame(height: configuration.timelineRulerHeight)
      .padding(.horizontal, width / 2)
      .padding(.bottom, 3)
  }

  private func timerLabelView() -> some View {
    Text(player.playheadPosition.imgly.formattedDurationMillisecondsStringForPlayer())
      .font(.footnote)
      .fontWeight(.semibold)
      .multilineTextAlignment(.center)
      .monospacedDigit()
      .contentTransition(.numericText())
  }

  private var timeIndicatorOverlay: some View {
    LineWithCirclesShape()
      .fill(Colors.timeIndicator)
      .shadow(color: colorScheme == .light ? .black.opacity(0.5) : .black, radius: 1, x: 0, y: 1)
      .padding(.top, configuration.timelineRulerHeight)
  }

  private func recordingStarterPlaceholer(width: CGFloat) -> some View {
    HStack(spacing: 6) {
      Image(systemName: Images.systemStartRecord)
      Text(Localization.labelStartRecording)
    }
    .font(.caption)
    .fontWeight(.medium)
    .foregroundStyle(.gray)
    .padding(.leading, width / 4 + 20)
    .padding(.top, configuration.timelineRulerHeight)
  }

  // MARK: - Helper Functions

  private func setupHorizontalScrollView(_ scrollView: UIScrollView) {
    guard scrollView !== horizontalScrollView else { return }
    DispatchQueue.main.async {
      scrollView.delegate = horizontalScrollViewDelegate
      horizontalScrollView = scrollView
      updateHorizontalOffset()
    }
  }

  private func updateHorizontalOffset() {
    guard let horizontalScrollView else { return }

    let contentOffsetX = timeline.convertToPoints(time: player.playheadPosition)
    let contentOffset = CGPoint(x: contentOffsetX, y: 0)
    horizontalScrollView.setContentOffset(contentOffset, animated: false)
  }

  private func handleScrollViewContentOffsetChange(_ newValue: CGPoint) {
    if horizontalScrollViewDelegate.isDraggingOrDecelerating {
      let time = timeline.convertToTime(points: newValue.x)
      timeline.interactor?.setPlayheadPosition(time)
    }
  }
}
