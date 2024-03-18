import SwiftUI

/// A call-to-action button that sits next to the timeline.
struct AddAudioButton: View {
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration
  @EnvironmentObject var interactor: AnyTimelineInteractor
  @EnvironmentObject var timeline: Timeline

  var body: some View {
    Button {
      interactor.addAudioAsset()
    } label: {
      HStack {
        Label {
          Text("Add Audio")
        } icon: {
          Image("custom.camera.audio.badge.plus", bundle: .module)
        }
        Spacer()
      }
      .frame(minWidth: 100)
      .frame(maxHeight: .infinity)
      .contentShape(Rectangle())
    }
    .padding(.horizontal)
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
  }
}
