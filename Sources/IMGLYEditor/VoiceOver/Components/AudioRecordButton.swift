import SwiftUI

struct AudioRecordButton: View {
  // MARK: - Constants

  private enum Localization {
    static let buttonResume: LocalizedStringKey = "Resume"
    static let buttonReplace: LocalizedStringKey = "Replace"
    static let startHint: LocalizedStringKey = "Starts the recording"
    static let pauseHint: LocalizedStringKey = "Pauses the recording"
    static let resumeHint: LocalizedStringKey = "Resumes the recording"
    static let replaceHint: LocalizedStringKey = "Replaces the current recording"
  }

  private enum Images {
    static var systemRecordButton: String { "mic.fill" }
    static var systemPauseButton: String { "pause.fill" }
  }

  private enum Metrics {
    static let cornerRadius: CGFloat = 36
  }

  // MARK: - Properties

  @Namespace private var nameSpaceImage

  let action: () -> Void
  var state: RecordingState
  var isEnabled: Bool

  // MARK: - View

  var body: some View {
    Button(action: action) {
      HStack {
        Spacer()
        buttonContent(for: state)
          .padding(.top, 12)
        Spacer()
      }
      .frame(minWidth: 99, maxHeight: 70)
    }
    .disabled(!isEnabled)
    .opacity(isEnabled ? 1 : 0.3)
    .animation(.easeInOut, value: isEnabled)
    .accessibility(addTraits: .isButton)
    .accessibility(label: Text(accessibilityLabel(for: state)))
    .accessibility(hint: Text(accessibilityHint(for: state)))
  }

  // MARK: - UI Components

  @ViewBuilder
  private func buttonContent(for state: RecordingState) -> some View {
    ZStack {
      // Background color
      RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .circular)
        .fill(state.fillColor)
        .frame(width: state.width, height: state.height)
        .padding(state != .pause ? 6 : 0)
        .animation(.snappy(extraBounce: 0.1), value: state)
        .overlay(
          RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .circular)
            .stroke(state.strokeColor, lineWidth: 2)
            .opacity(state.haveStroke ? 1 : 0)
            .animation(state.haveStroke ? .snappy(extraBounce: 0.2) : .none, value: state)
        )

      // Content Overlay
      switch state {
      case .start:
        Image(systemName: Images.systemRecordButton)
          .foregroundColor(state.foregroundColor)
          .transition(.opacity)
          .animation(.easeInOut.delay(0.09), value: state)
          .matchedGeometryEffect(id: nameSpaceImage, in: nameSpaceImage)

      case .pause:
        Image(systemName: Images.systemPauseButton)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 26, height: 28)
          .foregroundColor(state.foregroundColor)
          .transition(.opacity)
          .animation(.easeInOut.delay(0.09), value: state)
          .matchedGeometryEffect(id: nameSpaceImage, in: nameSpaceImage)

      case .resume, .replace:
        Text(state.displayText)
          .foregroundColor(state.foregroundColor)
          .transition(.opacity)
          .animation(.easeInOut.delay(0.09), value: state)
      }
    }
  }

  // Accessibility
  private func accessibilityLabel(for state: RecordingState) -> LocalizedStringKey {
    switch state {
    case .start: return Localization.startHint
    case .pause: return Localization.pauseHint
    case .resume: return Localization.buttonResume
    case .replace: return Localization.buttonReplace
    }
  }

  private func accessibilityHint(for state: RecordingState) -> LocalizedStringKey {
    switch state {
    case .start: return Localization.startHint
    case .pause: return Localization.pauseHint
    case .resume: return Localization.resumeHint
    case .replace: return Localization.replaceHint
    }
  }
}

// MARK: RecordingState

extension RecordingState {
  var width: CGFloat {
    switch self {
    case .start: return 50
    case .pause: return 62
    case .resume, .replace: return 99
    }
  }

  var height: CGFloat {
    switch self {
    case .start: return 50
    case .pause: return 62
    case .resume, .replace: return 50
    }
  }

  var fillColor: Color {
    switch self {
    case .start: return .pink
    case .pause: return .pink.opacity(0.3)
    case .resume: return .pink.opacity(0.16)
    case .replace: return .pink
    }
  }

  var haveStroke: Bool {
    switch self {
    case .start, .resume, .replace: return true
    case .pause: return false
    }
  }

  var strokeColor: Color {
    switch self {
    case .start: return .gray.opacity(0.5)
    case .pause: return .clear
    case .resume: return .pink
    case .replace: return .gray.opacity(0.5)
    }
  }

  var displayText: String {
    switch self {
    case .resume: return "Resume"
    case .replace: return "Replace"
    default: return ""
    }
  }

  var foregroundColor: Color {
    switch self {
    case .start: return .white
    case .pause: return .pink
    case .resume: return .pink
    case .replace: return .white
    }
  }
}

// MARK: - Previews

#Preview {
  AudioRecordButton(action: {}, state: .start, isEnabled: true)
}
