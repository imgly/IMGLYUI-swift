import SwiftUI
@_spi(Internal) import IMGLYCore

struct ClipSpeedOptions: View {
  @Environment(\.imglySelection) private var id
  @FocusState private var focusedField: ClipSpeedField?
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
    let previousSpeed = viewModel.previousStepValue(state.speed)
    let nextSpeed = viewModel.nextStepValue(state.speed)
    let previousSpeedProvider = { viewModel.previousStepValue(viewModel.state.speed) }
    let nextSpeedProvider = { viewModel.nextStepValue(viewModel.state.speed) }
    let isOverAudioCutoff = viewModel.isOverAudioCutoff(for: state)

    ZStack(alignment: .bottom) {
      VStack(spacing: 16) {
        VStack(spacing: 0) {
          ClipSpeedRow(
            title: .imgly.localized("ly_img_editor_sheet_clip_speed_speed_label"),
            value: viewModel.speedInputBinding,
            placeholder: "--",
            suffix: ClipSpeedDefaults.speedSuffix,
            isEnabled: state.isEnabled,
            inputWidth: ClipSpeedDefaults.speedInputWidth,
            focusedField: $focusedField,
            field: .speed,
            previousSpeed: previousSpeed,
            nextSpeed: nextSpeed,
            previousSpeedProvider: previousSpeedProvider,
            nextSpeedProvider: nextSpeedProvider,
            onSpeedSelected: { newSpeed in
              focusedField = nil
              viewModel.handleSpeedSelection(newSpeed)
            },
          )

          Divider()

          ClipSpeedRow(
            title: .imgly.localized("ly_img_editor_sheet_clip_speed_duration_label"),
            value: viewModel.durationInputBinding,
            placeholder: "--",
            suffix: "s",
            isEnabled: durationEnabled,
            inputWidth: ClipSpeedDefaults.durationInputWidth,
            focusedField: $focusedField,
            field: .duration,
          )
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
      }
      if viewModel.showNoAudioToast {
        ClipSpeedToastView(onDismiss: viewModel.dismissToast)
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
        .onTapGesture {
          if focusedField != nil {
            focusedField = nil
          }
        },
    )
    .animation(.easeInOut(duration: 0.2), value: viewModel.showNoAudioToast)
    .toolbar {
      ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button {
          focusedField = nil
        } label: {
          Text(.imgly.localized("ly_img_editor_common_button_done"))
        }
        .font(.body.weight(.semibold))
        .disabled(focusedField == nil)
      }
    }
    .onAppear {
      viewModel.updateSelection(id)
    }
    .onChange(of: id) { newID in
      viewModel.updateSelection(newID)
    }
    .onChange(of: state.speed) { _ in viewModel.syncInputs() }
    .onChange(of: state.durationSeconds) { _ in viewModel.syncInputs() }
    .onChange(of: isOverAudioCutoff) { isOver in
      viewModel.handleAudioCutoffChange(isOver: isOver)
    }
    .onChange(of: focusedField) { newField in
      viewModel.handleFocusChange(newField)
    }
  }
}
