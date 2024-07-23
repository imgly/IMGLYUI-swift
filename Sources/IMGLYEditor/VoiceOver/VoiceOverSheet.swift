import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct VoiceOverSheet: View {
  // MARK: Properties

  @Environment(\.imglySelection) private var audioBlockSelected
  @EnvironmentObject private var interactor: Interactor

  // MARK: - Body

  var body: some View {
    VoiceOverSheetContent(interactor: interactor, audioBlock: audioBlockSelected)
  }
}

struct VoiceOverSheetContent: View {
  // MARK: Properties

  @StateObject private var viewModel: VoiceOverViewModel

  // MARK: - Initializers

  init(interactor: Interactor, audioBlock: Interactor.BlockID?) {
    let interactorTimeline = AnyTimelineInteractor(erasing: interactor)
    let player = interactor.timelineProperties.player

    /// we can only have one type of voiceover, so if one already exist, we should edit it
    let audioBlockId = audioBlock ?? interactor.timelineProperties.dataSource.foregroundClips()
      .first(where: { $0.clipType == .voiceOver })?.id

    _viewModel = StateObject(wrappedValue: VoiceOverViewModel(audioBlock: audioBlockId,
                                                              audioManager: AudioRecordManager(),
                                                              audioProvider: AudioProvider(interactor: interactor),
                                                              interactor: interactorTimeline,
                                                              player: player))
  }

  // MARK: - Body

  var body: some View {
    BottomSheet {
      VoiceOverView(viewModel: viewModel)
        .modifier(InteractableVoiceOver())
    }
    .preference(key: PresentationDragIndicatorHiddenKey.self, value: true)
    .interactiveDismissDisabled()
  }
}

private struct InteractableVoiceOver: ViewModifier {
  @EnvironmentObject private var interactor: Interactor

  func body(content: Content) -> some View {
    if let timeline = interactor.timelineProperties.timeline {
      content
        .environmentObject(timeline)
        .environmentObject(AnyTimelineInteractor(erasing: interactor))
        .environmentObject(interactor.timelineProperties.player)
    } else {
      content
    }
  }
}
