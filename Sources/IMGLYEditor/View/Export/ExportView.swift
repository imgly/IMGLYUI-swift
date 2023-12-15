import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

struct ExportView: View {
  enum State {
    case exporting(ExportProgress, cancelAction: () -> Void)
    case completed(title: LocalizedStringKey = "Close", completedAction: () -> Void)
    case error(Swift.Error, closeAction: () -> Void)
  }

  let state: State

  private struct Header<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
      content()
        .font(.system(size: 128))
        .padding(.bottom, 23)
    }
  }

  private struct Message<Button: View>: View {
    let title, text: LocalizedStringKey
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

  private func format(percentage: Float) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 1
    return formatter.string(from: .init(value: percentage.clamped(to: 0 ... 1))) ?? ""
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
              VStack {
                ProgressView(value: percentage)
                  .animation(percentage != 0 ? .default : nil, value: percentage)
                Text(format(percentage: percentage))
                  .font(.footnote.weight(.semibold).monospacedDigit())
              }
            }
          }
        }
        Message(title: "Exporting",
                text: "Just a few seconds...") {
          Button(role: .cancel) {
            cancelAction()
          } label: {
            Text("Cancel")
          }
        }
      case let .completed(title, completedAction):
        Header {
          Image(systemName: "checkmark.circle")
            .foregroundColor(.green)
        }
        Message(title: "Export Complete",
                text: "All done. You can close this dialog.") {
          Button(title, action: completedAction)
        }
      case let .error(_, closeAction):
        Header {
          Image(systemName: "exclamationmark.circle")
            .foregroundColor(.red)
        }
        Message(title: "Something went wrong",
                text: "We were not able to prepare your export.  Please, try again later.") {
          Button("Close", action: closeAction)
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
      return .completed(title: "Halleluja") {
        state = nextState(state)
      }
    case .completed:
      return .error(Error(errorDescription: "Something really bad.")) {
        state = nextState(state)
      }
    case .error:
      return .exporting(.spinner) {
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
