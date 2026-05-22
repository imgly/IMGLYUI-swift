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

  /// Engine-backed tracks (multi-clip foreground *and* background) lay out via
  /// `clip.displayTimeOffset`, so the `previewTimeOffset` cascade applies to both.
  /// Standalone foreground clips stick with HStack.
  private var usesAbsolutePositioning: Bool {
    track.engineTrackID != nil
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        if let placeholder = draftVoiceOverPlaceholder(in: geometry.size.width) {
          placeholder
        }

        if usesAbsolutePositioning {
          ForEach(track.clips, id: \.id) { clip in
            clipView(for: clip)
          }
        } else {
          HStack(spacing: 0) {
            ForEach(track.clips, id: \.id) { clip in
              clipView(for: clip)
            }
          }
        }

        DropSlotIndicatorView(trackID: track.id)
      }
      .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
      // Publish this track's global-space frame so drag & drop can resolve a target
      // track from the pan gesture's window-space pointer.
      .background(
        GeometryReader { proxy in
          Color.clear.preference(
            key: TrackFramesPreferenceKey.self,
            value: [track.id: proxy.frame(in: .global)],
          )
        },
      )
    }
  }

  @ViewBuilder
  private func clipView(for clip: Clip) -> some View {
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
