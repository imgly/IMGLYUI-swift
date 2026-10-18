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

        ForEach(track.transitionSeams) { seam in
          if let outgoing = track.clips.first(where: { $0.id == seam.outgoingID }),
             let incoming = track.clips.first(where: { $0.id == seam.incomingID }) {
            TransitionSeamPlacement(
              track: track,
              seam: seam,
              outgoing: outgoing,
              incoming: incoming,
              yPosition: geometry.size.height / 2,
            )
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

/// Positions a seam from the live clip-preview offsets. The track itself does not
/// publish changes made to an individual clip during a drag, so this view observes
/// both clips directly instead of leaving seam placement at its pre-drag location.
/// Only the source and current destination tracks consume the preview, matching
/// Android's affected-track scope.
private struct TransitionSeamPlacement: View {
  @EnvironmentObject private var timeline: Timeline
  @EnvironmentObject private var timelineProperties: TimelineProperties

  @ObservedObject var track: Track
  let seam: TransitionSeam
  @ObservedObject var outgoing: Clip
  @ObservedObject var incoming: Clip
  let yPosition: CGFloat

  var body: some View {
    if outgoing.id != timelineProperties.selectedClip?.id,
       incoming.id != timelineProperties.selectedClip?.id,
       !isOccupiedByDraggedClip,
       let duration = outgoing.duration {
      let outgoingOffset = isAffectedByCurrentDrag ? outgoing.displayTimeOffset : outgoing.timeOffset
      let incomingOffset = isAffectedByCurrentDrag ? incoming.displayTimeOffset : incoming.timeOffset
      let renderedSeamTime = CMTime(seconds: (outgoingOffset + duration + incomingOffset).seconds / 2)
      let outgoingEnd = timeline.convertToPoints(time: outgoingOffset + duration)
      let incomingStart = timeline.convertToPoints(time: incomingOffset)
      if renderedSeamTime < timeline.totalDuration {
        TransitionSeamView(hasTransition: seam.hasTransition, isCompact: seam.isCompact) {
          timeline.interactor?.openTransition(for: outgoing.id)
        }
        .position(x: (outgoingEnd + incomingStart) / 2, y: yPosition)
        .zIndex(3)
      }
    }
  }

  private var isAffectedByCurrentDrag: Bool {
    guard case let .dragging(context) = timelineProperties.dragDropState else { return false }
    if context.sourceTrackID == track.id {
      return true
    }
    if case let .existingTrack(trackID, _, _, _) = context.dropTarget {
      return trackID == track.id
    }
    return false
  }

  /// The drop index is calculated from the target track with the dragged clip
  /// excluded. Its immediate neighbours are the seam the floating clip occupies,
  /// which must be hidden until the drop is committed.
  private var isOccupiedByDraggedClip: Bool {
    guard case let .dragging(context) = timelineProperties.dragDropState,
          case let .existingTrack(trackID, insertIndex, _, _) = context.dropTarget,
          trackID == track.id else {
      return false
    }
    let siblings = track.clips
      .filter { $0.id != context.clipID }
      .sorted { $0.timeOffset < $1.timeOffset }
    guard insertIndex > 0, insertIndex < siblings.count else { return false }
    return outgoing.id == siblings[insertIndex - 1].id && incoming.id == siblings[insertIndex].id
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
