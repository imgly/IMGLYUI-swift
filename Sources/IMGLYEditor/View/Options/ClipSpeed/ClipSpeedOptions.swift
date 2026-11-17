import SwiftUI
@_spi(Internal) import IMGLYCore

struct ClipSpeedOptions: View {
  @Environment(\.imglySelection) private var id
  @StateObject private var viewModel: ViewModel

  init(interactor: Interactor, timelineConfiguration: TimelineConfiguration) {
    _viewModel = StateObject(wrappedValue: ViewModel(
      interactor: interactor,
      timelineConfiguration: timelineConfiguration,
    ))
  }

  var body: some View {
    let state = viewModel.state
    let durationEnabled = viewModel.durationEnabled(for: state)
    let isOverAudioCutoff = viewModel.isOverAudioCutoff(for: state)

    ZStack(alignment: .bottom) {
      VStack(spacing: 16) {
        VStack(spacing: 0) {
          ClipSpeedRow(
            title: .imgly.localized("ly_img_editor_sheet_clip_speed_speed_label"),
            value: viewModel.speedBinding,
            bounds: ClipSpeedDefaults.minSpeed ... state.maxSpeed,
            step: ClipSpeedDefaults.step,
            unit: String(localized: .imgly.localized("ly_img_editor_sheet_clip_speed_speed_suffix")),
            decimals: ClipSpeedDefaults.speedInputDecimals,
            isEnabled: state.isEnabled,
            showsButtons: true,
            onEditingChanged: { isEditing in
              if !isEditing {
                viewModel.addUndoStep()
              }
            },
          )

          Divider()

          ClipSpeedRow(
            title: .imgly.localized("ly_img_editor_sheet_clip_speed_duration_label"),
            value: viewModel.durationBinding,
            bounds: viewModel.durationBounds,
            step: ClipSpeedDefaults.durationStep,
            unit: String(localized: .imgly.localized("ly_img_editor_sheet_clip_speed_duration_suffix")),
            decimals: ClipSpeedDefaults.durationInputDecimals,
            isEnabled: durationEnabled,
            showsButtons: false,
            onEditingChanged: { isEditing in
              if !isEditing {
                viewModel.addUndoStep()
              }
            },
          )
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
      }
      if viewModel.showNoAudioToast {
        ToastView(
          message: .imgly.localized("ly_img_editor_notification_speed_no_audio_at_speed"),
          onDismiss: viewModel.dismissToast,
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .transition(.opacity)
        .zIndex(1)
      }
    }
    .padding(.top, 8)
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(
      Color(.systemGroupedBackground)
        .contentShape(Rectangle())
        .onTapGesture(perform: resignKeyboard),
    )
    .animation(.easeInOut(duration: 0.2), value: viewModel.showNoAudioToast)
    .onAppear {
      viewModel.updateSelection(id)
    }
    .onChange(of: id) { newID in
      viewModel.updateSelection(newID)
    }
    .onChange(of: isOverAudioCutoff) { isOver in
      viewModel.handleAudioCutoffChange(isOver: isOver)
    }
  }

  /// ``NumberStepperField`` keeps its focus state private, so resign the first
  /// responder to dismiss whichever field is focused.
  private func resignKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
