import SwiftUI

struct ReorderOptions: View {
  @EnvironmentObject var interactor: Interactor
  @StateObject private var viewModel = ViewModel()

  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(alignment: .center) {
        ReorderingView(
          track: interactor.timelineProperties.dataSource.backgroundTrack,
          onTransitionRemoved: viewModel.showTransitionRemovedToast,
        )
        .environmentObject(AnyTimelineInteractor(erasing: interactor))
      }
      .background(Color(.systemGroupedBackground))
      // The timeline hides while a sheet is open, so the sheet shows the toast of a reorder itself.
      if viewModel.isTransitionRemovedToastVisible {
        ToastView(
          message: .imgly.localized("ly_img_editor_timeline_transition_removed_on_move"),
          onDismiss: viewModel.dismissTransitionRemovedToast,
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .transition(.opacity)
        .zIndex(1)
      }
    }
  }
}

extension ReorderOptions {
  @MainActor
  final class ViewModel: ObservableObject {
    @Published var isTransitionRemovedToastVisible = false
    private var toastTask: Task<Void, Never>?

    func showTransitionRemovedToast() {
      toastTask?.cancel()
      withAnimation(.easeInOut(duration: 0.2)) {
        isTransitionRemovedToastVisible = true
      }
      toastTask = Task { @MainActor [weak self] in
        try? await Task.sleep(nanoseconds: 3_500_000_000)
        guard !Task.isCancelled else { return }
        self?.dismissTransitionRemovedToast()
      }
    }

    func dismissTransitionRemovedToast() {
      toastTask?.cancel()
      withAnimation(.easeInOut(duration: 0.2)) {
        isTransitionRemovedToastVisible = false
      }
    }
  }
}
