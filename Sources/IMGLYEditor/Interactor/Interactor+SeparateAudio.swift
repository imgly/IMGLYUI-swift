import Foundation
import IMGLYEngine
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

extension Interactor {
  /// Moves the audio of the selected clip into one new audio clip per audio track and mutes the clip. The audio clips
  /// start with the clip, play like it and are named after it, or "Audio" when it has no name. The audio of a
  /// background clip goes into the audio rows directly above the background track, the audio of an overlay into the
  /// audio rows directly below the overlays. The first track goes on top.
  func separateAudioOfSelectedClip() {
    guard let engine, let pageID = timelineProperties.currentPage, let clip = selection?.blocks.first else { return }
    Task {
      do {
        guard try engine.block.supportsFill(clip) else { return }
        let fill = try engine.block.getFill(clip)
        guard try engine.block.getType(fill) == FillType.video.rawValue else { return }
        try await engine.block.forceLoadAVResource(fill)
        guard try engine.block.getAudioTrackCountFromVideo(fill) > 0 else {
          self.error = AlertState(
            String(localized: .imgly.localized("ly_img_editor_dialog_separate_audio_no_audio_title")),
            message: String(localized: .imgly.localized("ly_img_editor_dialog_separate_audio_no_audio_text")),
            dismiss: false,
          )
          return
        }

        // The timeline shows the audio rows between the overlays and the background track, and the audio block with
        // the lower page index in the higher row.
        let topAudioRowIndex: Int? = if try engine.block.getParent(clip) == timelineProperties.backgroundTrack {
          nil
        } else {
          try engine.block.getChildren(pageID).firstIndex { try engine.block.isAudioLike($0) }
        }
        let audioBlocks = try engine.block.createAudiosFromVideo(
          fill,
          options: .init(keepTrimSettings: true, muteOriginalVideo: true),
        )
        let timeOffset = try engine.block.getTimeOffset(clip)
        let clipName = try engine.block.hasMetadata(clip, key: "name")
          ? engine.block.getMetadata(clip, key: "name")
          : ""
        // A video from the photo roll has no name, so its audio clips get a default one.
        let audioName = clipName.isEmpty
          ? String(localized: .imgly.localized("ly_img_editor_timeline_clip_audio_title"))
          : clipName
        for (index, audioBlock) in audioBlocks.enumerated() {
          if let topAudioRowIndex {
            try engine.block.insertChild(into: pageID, child: audioBlock, at: topAudioRowIndex + index)
          } else {
            try engine.block.appendChild(to: pageID, child: audioBlock)
          }
          // Keeps the audio out of the z-index reordering, like an audio clip added from the library.
          try engine.block.setAlwaysOnTop(audioBlock, enabled: true)
          try engine.block.setTimeOffset(audioBlock, offset: timeOffset)
          // The engine names the block after the audio track, and the web timeline shows that name first.
          try engine.block.setName(audioBlock, name: "")
          let name = audioBlocks.count > 1 ? "\(audioName) \(index + 1)" : audioName
          try engine.block.setMetadata(audioBlock, key: "name", value: name)
        }
        addUndoStep()
      } catch {
        handleError(error)
      }
    }
  }
}
