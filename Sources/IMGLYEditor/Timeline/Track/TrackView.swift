import CoreMedia
import SwiftUI
@_spi(Internal) import IMGLYCore

/// Container for the `ClipView`s.
struct TrackView: View {
  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var player: Player
  @EnvironmentObject var timelineProperties: TimelineProperties
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  @ObservedObject var track: Track

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        if let placeholder = draftVoiceOverPlaceholder(in: geometry.size.width) {
          placeholder
        }

        HStack(spacing: 0) {
          ForEach(track.clips, id: \.id) { clip in
            ClipView(
              clip: clip,
              isSelected: clip == timelineProperties.selectedClip,
              clipSpacing: configuration.clipSpacing,
            )
            .onTapGesture(count: 1) {
              guard clip.allowsSelecting else {
                return
              }
              timeline.interactor?.select(id: clip.id)
            }
          }
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
    }
  }

  private func draftVoiceOverPlaceholder(in width: CGFloat) -> VoiceOverDraftPlaceholderView? {
    guard let interactor = timeline.interactor,
          interactor.isVoiceOverRecordModeActive,
          !interactor.hasVoiceOverRecordModeRecordedAudio,
          let targetID = interactor.voiceOverRecordModeTarget,
          let clip = track.clips.first(where: { $0.id == targetID && $0.clipType == .voiceOver }),
          (clip.duration?.seconds ?? 0) <= 0 else {
      return nil
    }

    let startTime = interactor.isVoiceOverRecordModeRecording ? clip.timeOffset : player.playheadPosition
    let trackWidth = max(width, timeline.totalWidth)
    let startOffset = timeline.convertToPoints(time: startTime).clamped(to: 0 ... trackWidth)
    let placeholderWidth = max(0, trackWidth - startOffset)

    guard placeholderWidth > 0 else {
      return nil
    }

    return VoiceOverDraftPlaceholderView(
      width: placeholderWidth,
      leadingOffset: startOffset,
      cornerRadius: configuration.cornerRadius,
      fillColor: clip.configuration.color,
    )
  }
}

private struct VoiceOverDraftPlaceholderView: View {
  let width: CGFloat
  let leadingOffset: CGFloat
  let cornerRadius: CGFloat
  let fillColor: Color

  @State private var alpha = 0.14

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(fillColor.opacity(alpha))
      .frame(width: width)
      .frame(maxHeight: .infinity)
      .offset(x: leadingOffset)
      .onAppear {
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
          alpha = 0.28
        }
      }
  }
}
