import CoreMedia
import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

private enum VoiceOverSheetLocalization {
  static let cancel: LocalizedStringResource = .imgly.localized("ly_img_editor_sheet_voiceover_button_dismiss")
  static let mute: LocalizedStringResource = .imgly.localized("ly_img_editor_sheet_voiceover_button_mute")
  static let unmute: LocalizedStringResource = .imgly.localized("ly_img_editor_sheet_voiceover_button_unmute")
  static let record: LocalizedStringResource = .imgly.localized("ly_img_editor_sheet_voiceover_button_record")
}

private enum VoiceOverSheetLayout {
  static let leadingPadding: CGFloat = 24
  static let trailingPadding: CGFloat = 16
  static let topPadding: CGFloat = 4
  static let controlsHeight: CGFloat = 64
  static let sideButtonSlotWidth: CGFloat = 92
  static let sideButtonSecondarySlotWidth: CGFloat = 112
  static let sideButtonPrimaryWidth: CGFloat = 72
  static let sideButtonSecondaryWidth: CGFloat = 112
  static let sideButtonVerticalOffset: CGFloat = 4
  static let sideButtonSpacing: CGFloat = 4
  static let sideButtonHeight: CGFloat = 56
  static let sideButtonLabelHeight: CGFloat = 13
  static let sideButtonIconHeight: CGFloat = 24
  static let sideButtonIconSize: CGFloat = 17
  static let recordOuterIdleWidth: CGFloat = 109
  static let recordOuterRecordingWidth: CGFloat = 134
  static let recordOuterHeight: CGFloat = 64
  static let recordInnerIdleWidth: CGFloat = 101
  static let recordInnerRecordingWidth: CGFloat = 126
  static let recordInnerHeight: CGFloat = 56
  static let recordLabelSpacing: CGFloat = 2
  static let recordIconSize: CGFloat = 18
  static let stopIconSize: CGFloat = 11
}

struct VoiceOverSheet: View {
  @EnvironmentObject private var interactor: Interactor

  private var sideButtonForegroundColor: Color {
    Color(uiColor: .label)
  }

  var body: some View {
    ZStack(alignment: .top) {
      HStack(alignment: .top, spacing: 0) {
        sideButton(
          title: VoiceOverSheetLocalization.cancel,
          systemImage: "xmark",
          width: VoiceOverSheetLayout.sideButtonPrimaryWidth,
        ) {
          Task {
            await interactor.cancelVoiceOverRecordMode()
          }
        }
        .frame(width: VoiceOverSheetLayout.sideButtonSlotWidth, alignment: .leading)

        Spacer(minLength: 0)

        sideButton(
          title: interactor.isVoiceOverRecordModeMuteOtherAudio ? VoiceOverSheetLocalization.unmute :
            VoiceOverSheetLocalization.mute,
          systemImage: interactor.isVoiceOverRecordModeMuteOtherAudio ? "speaker.slash.fill" : "speaker.wave.2.fill",
          width: VoiceOverSheetLayout.sideButtonSecondaryWidth,
        ) {
          interactor.toggleVoiceOverRecordModeMuteOtherAudio()
        }
        .frame(width: VoiceOverSheetLayout.sideButtonSecondarySlotWidth, alignment: .trailing)
      }
      .padding(.leading, VoiceOverSheetLayout.leadingPadding)
      .padding(.trailing, VoiceOverSheetLayout.trailingPadding)

      VoiceOverRecordButton(
        isRecording: interactor.isVoiceOverRecordModeRecording,
        elapsedDuration: interactor.voiceOverRecordModeElapsedDuration,
      ) {
        Task {
          if interactor.isVoiceOverRecordModeRecording {
            await interactor.finishVoiceOverRecordMode()
          } else {
            await interactor.toggleVoiceOverRecordModeRecording()
          }
        }
      }
    }
    .padding(.top, VoiceOverSheetLayout.topPadding)
    .frame(height: VoiceOverSheetLayout.controlsHeight, alignment: .top)
    .frame(maxWidth: .infinity, alignment: .center)
    .preference(key: PresentationDragIndicatorHiddenKey.self, value: true)
    .interactiveDismissDisabled()
  }

  @ViewBuilder
  private func sideButton(
    title: LocalizedStringResource,
    systemImage: String,
    width: CGFloat,
    action: @escaping () -> Void,
  ) -> some View {
    Button(action: action) {
      VStack(spacing: VoiceOverSheetLayout.sideButtonSpacing) {
        Image(systemName: systemImage)
          .font(.system(size: VoiceOverSheetLayout.sideButtonIconSize, weight: .semibold))
          .frame(height: VoiceOverSheetLayout.sideButtonIconHeight)
        Text(title)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(sideButtonForegroundColor)
          .multilineTextAlignment(.center)
          .lineLimit(1)
          .allowsTightening(true)
          .minimumScaleFactor(0.8)
          .frame(height: VoiceOverSheetLayout.sideButtonLabelHeight, alignment: .top)
      }
      .frame(width: width, height: VoiceOverSheetLayout.sideButtonHeight)
      .offset(y: VoiceOverSheetLayout.sideButtonVerticalOffset)
      .frame(width: width, height: VoiceOverSheetLayout.controlsHeight, alignment: .top)
    }
    .buttonStyle(.plain)
    .foregroundStyle(sideButtonForegroundColor)
  }
}

private struct VoiceOverRecordButton: View {
  let isRecording: Bool
  let elapsedDuration: TimeInterval
  let action: () -> Void

  private var borderColor: Color {
    isRecording ? Color(uiColor: .systemPink) : Color(uiColor: .separator)
  }

  private var containerColor: Color {
    isRecording ? Color(uiColor: .systemPink).opacity(0.16) : Color(uiColor: .systemPink)
  }

  private var contentColor: Color {
    isRecording ? Color(uiColor: .systemPink) : .white
  }

  private var outerWidth: CGFloat {
    isRecording ? VoiceOverSheetLayout.recordOuterRecordingWidth : VoiceOverSheetLayout.recordOuterIdleWidth
  }

  private var innerWidth: CGFloat {
    isRecording ? VoiceOverSheetLayout.recordInnerRecordingWidth : VoiceOverSheetLayout.recordInnerIdleWidth
  }

  @ViewBuilder
  private var label: some View {
    if isRecording {
      Text(formattedDuration)
    } else {
      Text(VoiceOverSheetLocalization.record)
    }
  }

  private var formattedDuration: String {
    CMTime(seconds: max(0, elapsedDuration)).imgly.formattedDurationMillisecondsStringForPlayer()
  }

  var body: some View {
    Button(action: action) {
      Capsule(style: .continuous)
        .stroke(borderColor, lineWidth: 2)
        .frame(width: outerWidth, height: VoiceOverSheetLayout.recordOuterHeight)
        .overlay {
          Capsule(style: .continuous)
            .fill(containerColor)
            .frame(width: innerWidth, height: VoiceOverSheetLayout.recordInnerHeight)
            .overlay {
              VStack(spacing: VoiceOverSheetLayout.recordLabelSpacing) {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                  .font(.system(
                    size: isRecording ? VoiceOverSheetLayout.stopIconSize : VoiceOverSheetLayout.recordIconSize,
                    weight: .semibold,
                  ))
                  .foregroundStyle(contentColor)
                  .frame(height: VoiceOverSheetLayout.sideButtonIconHeight)
                label
                  .font(.caption2.weight(.semibold))
                  .foregroundStyle(contentColor)
              }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isRecording)
    }
    .buttonStyle(.plain)
  }
}
