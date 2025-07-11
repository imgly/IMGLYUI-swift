import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

struct ExportView: View {
  enum State {
    case exporting(ExportProgress, cancelAction: () -> Void)
    case completed(
      title: LocalizedStringResource = .imgly.localized("ly_img_editor_dialog_export_success_button_dismiss"),
      completedAction: () -> Void
    )
    case error(Swift.Error, closeAction: () -> Void)
  }

  let state: State
  @SwiftUI.State private var isShowingCancelExportDialog = false

  private struct Header<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
      content()
        .font(.system(size: 128))
        .padding(.bottom, 23)
    }
  }

  private struct Message<Button: View>: View {
    let title, text: LocalizedStringResource
    @ViewBuilder let button: () -> Button

    var body: some View {
      Group {
        Text(title)
          .font(.title2.weight(.bold))
        Text(text)
          .font(.footnote)
          .padding(.bottom, 29)
          .lineLimit(2, reservesSpace: true) // Reserve space to match other states
      }
      .multilineTextAlignment(.center)
      button()
    }
  }

  var body: some View {
    VStack(spacing: 4) {
      switch state {
      case let .exporting(progress, cancelAction):
        Header {
          ZStack {
            Image(systemName: "circle")
              .hidden() // Reserve space to match other states
            switch progress {
            case .spinner:
              ProgressView()
            case let .relative(percentage):
              CircularProgressIndicator(current: Double(percentage), total: 1)
                .padding()
                .padding(.top, 20)
            }
          }
        }
        Message(title: .imgly.localized("ly_img_editor_dialog_export_progress_title"),
                text: .imgly.localized("ly_img_editor_dialog_export_progress_text")) {
          Button(role: .cancel) {
            isShowingCancelExportDialog = true
          } label: {
            Text(.imgly.localized("ly_img_editor_dialog_export_progress_button_dismiss"))
          }
        }
        .interactiveDismissDisabled()
        .confirmationDialog(
          Text(.imgly.localized("ly_img_editor_dialog_export_cancel_title")),
          isPresented: $isShowingCancelExportDialog,
          titleVisibility: .visible
        ) {
          Button(role: .destructive) {
            cancelAction()
          } label: {
            Text(.imgly.localized("ly_img_editor_dialog_export_cancel_button_confirm"))
          }
          Button(role: .cancel) {
            isShowingCancelExportDialog = false
          } label: {
            Text(.imgly.localized("ly_img_editor_dialog_export_cancel_button_dismiss"))
          }
        } message: {
          Text(.imgly.localized("ly_img_editor_dialog_export_cancel_text"))
        }
      case let .completed(title, completedAction):
        Header {
          Image(systemName: "checkmark.circle")
            .foregroundColor(.green)
        }
        Message(title: .imgly.localized("ly_img_editor_dialog_export_success_title"),
                text: .imgly.localized("ly_img_editor_dialog_export_success_text")) {
          Button {
            completedAction()
          } label: {
            Text(title)
          }
        }
      case let .error(_, closeAction):
        Header {
          Image(systemName: "exclamationmark.circle")
            .foregroundColor(.red)
        }
        Message(title: .imgly.localized("ly_img_editor_dialog_export_error_title"),
                text: .imgly.localized("ly_img_editor_dialog_export_error_text")) {
          Button {
            closeAction()
          } label: {
            Text(.imgly.localized("ly_img_editor_dialog_export_error_button_dismiss"))
          }
        }
      }
    }
  }
}

// MARK: - Preview

struct ExportView_Previews: PreviewProvider {
  static var previews: some View {
    ExportView(state: .exporting(.spinner) {})
      .previewDisplayName("Spinner")

    previewState(Float(0)) { binding in
      ExportView(state: .exporting(.relative(binding.wrappedValue)) {})
        .simulateProgress(binding)
    }
    .previewDisplayName("Precentage")

    ExportView(state: .completed(title: "Halleluja") {})
      .previewDisplayName("Completed")

    ExportView(state: .error(Error(errorDescription: "Something really bad.")) {})
      .previewDisplayName("Error")

    ExportFlowPreview()
      .previewDisplayName("Flow")
  }
}

private struct ExportFlowPreview: View {
  @State var state: ExportView.State = .error(Error(errorDescription: "Something really bad.")) {}

  func nextState(_ currentState: ExportView.State) -> ExportView.State {
    switch currentState {
    case .exporting:
      .completed(title: "Halleluja") {
        state = nextState(state)
      }
    case .completed:
      .error(Error(errorDescription: "Something really bad.")) {
        state = nextState(state)
      }
    case .error:
      .exporting(.spinner) {
        state = nextState(state)
      }
    }
  }

  var body: some View {
    ExportView(state: nextState(state))
  }
}

private extension View {
  @MainActor
  func simulateProgress(_ binding: Binding<some BinaryFloatingPoint>) -> some View {
    task {
      while !Task.isCancelled {
        if binding.wrappedValue > 1 {
          binding.wrappedValue = 0
        } else {
          binding.wrappedValue += 0.123
        }
        try? await Task.sleep(for: .milliseconds(1000))
      }
    }
  }
}
