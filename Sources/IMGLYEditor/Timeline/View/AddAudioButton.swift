import SwiftUI

/// A call-to-action button that sits next to the timeline.
struct AddAudioButton: View {
  // MARK: Properties

  private enum Localization {
    static var buttonAddAudio: LocalizedStringResource { .imgly.localized("ly_img_editor_timeline_button_add_audio") }
    static var buttonAddMusic: LocalizedStringResource {
      .imgly.localized("ly_img_editor_timeline_add_audio_option_music")
    }

    static var buttonAddVoiceover: LocalizedStringResource {
      .imgly.localized("ly_img_editor_timeline_add_audio_option_voiceover")
    }

    static var accessabilityAddAudio: LocalizedStringKey { "Add Audio Menu" }
    static var accessabilityAddMusic: LocalizedStringKey { "Add Music" }
    static var accessabilityAddVoiceover: LocalizedStringKey { "Add Voiceover" }
  }

  private enum Images {
    static var customMusic: String { "custom.audio.badge.plus" }
    static var customVoiceover: String { "custom.mic.badge.plus" }
    static var systemPlus: String { "plus" }
  }

  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration
  @EnvironmentObject var interactor: AnyTimelineInteractor

  // MARK: Body

  var body: some View {
    Menu(content: menuContent, label: menuLabel)
      .menuOrder(.fixed)
      .frame(height: configuration.backgroundTrackHeight)
      .buttonStyle(.plain)
      .font(.caption)
      .fontWeight(.semibold)
      .background {
        RoundedRectangle(cornerRadius: configuration.cornerRadius)
          .fill(Color(uiColor: .systemGray6))
      }
      .overlay {
        RoundedRectangle(cornerRadius: configuration.cornerRadius)
          .inset(by: 0.25)
          .stroke(Color(uiColor: .separator), lineWidth: 0.5)
      }
      .fixedSize(horizontal: true, vertical: false)
      .accessibilityLabel(Text(Localization.accessabilityAddAudio))
  }

  private func menuContent() -> some View {
    Group {
      Button {
        interactor.addAudioAsset()
      } label: {
        Label {
          Text(Localization.buttonAddMusic)
        } icon: {
          Image(Images.customMusic, bundle: .module)
        }
      }
      .accessibilityLabel(Text(Localization.accessabilityAddMusic))

      Button {
        interactor.openVoiceOver(style: .only(detent: .imgly.medium))
      } label: {
        Label {
          Text(Localization.buttonAddVoiceover)
        } icon: {
          Image(Images.customVoiceover, bundle: .module)
        }
      }
      .accessibilityLabel(Text(Localization.accessabilityAddVoiceover))
    }
  }

  private func menuLabel() -> some View {
    HStack {
      Label {
        Text(Localization.buttonAddAudio)
      } icon: {
        Image(systemName: Images.systemPlus)
      }
      Spacer()
    }
    .frame(minWidth: 100)
    .frame(maxHeight: .infinity)
    .padding(.horizontal)
    .contentShape(Rectangle())
  }
}
