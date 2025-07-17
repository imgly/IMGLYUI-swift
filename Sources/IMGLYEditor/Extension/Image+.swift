import IMGLYCore
import SwiftUI

extension Image: IMGLYCompatible {}

public extension IMGLY where Wrapped == Image {
  /// An icon image for adding an element from the library.
  static let addElement = Wrapped("custom.books.vertical.badge.plus", bundle: .module)
  /// An icon image for adding a video.
  static let addVideo = Wrapped("custom.film.stack.badge.plus", bundle: .module)
  /// An icon image for adding audio.
  static let addAudio = Wrapped("custom.audio.badge.plus", bundle: .module)
  /// An icon image for adding an image.
  static let addImage = Wrapped("custom.photo.badge.plus", bundle: .module)
  /// An icon image for adding text.
  static let addText = Wrapped("custom.textformat.alt.badge.plus", bundle: .module)
  /// An icon image for adding a shape.
  static let addShape = Wrapped("custom.square.on.circle.badge.plus", bundle: .module)
  /// An icon image for adding a sticker.
  static let addSticker = Wrapped("custom.face.smiling.badge.plus", bundle: .module)

  /// An icon image for adding content from the photo roll to the background track.
  static let addPhotoRollBackground = Wrapped("custom.photo.fill.on.rectangle.fill.badge.plus", bundle: .module)
  /// An icon image for adding content from the photo roll.
  static let addPhotoRollForeground = Wrapped("custom.photo.on.rectangle.badge.plus", bundle: .module)
  /// An icon image for adding content from the camera to the background track.
  static let addCameraBackground = Wrapped("custom.camera.fill.badge.plus", bundle: .module)
  /// An icon image for adding content from the camera.
  static let addCameraForeground = Wrapped("custom.camera.badge.plus", bundle: .module)
  /// An icon image for adding a voiceover.
  static let addVoiceover = Wrapped("custom.mic.badge.plus", bundle: .module)

  /// An icon image for editing a voiceover.
  static let editVoiceover = Wrapped("custom.waveform.badge.mic", bundle: .module)

  /// An icon image for reoder.
  static let reorder = Wrapped(systemName: "rectangle.portrait.arrowtriangle.2.outward")
  /// An icon image for adjustments.
  static let adjustments = Wrapped(systemName: "slider.horizontal.3")
  /// An icon image for filter.
  static let filter = Wrapped(systemName: "camera.filters")
  /// An icon image for effect.
  static let effect = Wrapped(systemName: "fx")
  /// An icon image for blur.
  static let blur = Wrapped(systemName: "aqi.medium")
  /// An icon image for volume.
  static let volume = Wrapped(systemName: "speaker.wave.3.fill")
  /// An icon image for crop.
  static let crop = Wrapped(systemName: "crop.rotate")
  /// An icon image for resize.
  static let resize = Wrapped("custom.arrow.down.left.and.arrow.up.right", bundle: .module)

  /// An icon image for duplicate.
  static let duplicate = Wrapped(systemName: "plus.square.on.square")
  /// An icon image for layer.
  static let layer = Wrapped(systemName: "square.3.stack.3d")
  /// An icon image for split.
  static let split = Wrapped(systemName: "square.and.line.vertical.and.square")
  /// An icon image for move as clip.
  static let moveAsClip = Wrapped("custom.as.clip", bundle: .module)
  /// An icon image for move as overlay.
  static let moveAsOverlay = Wrapped("custom.as.overlay", bundle: .module)
  /// An icon image for replace.
  static let replace = Wrapped(systemName: "arrow.left.arrow.right.square")
  /// An icon image for enter group.
  static let enterGroup = Wrapped("custom.group.enter", bundle: .module)
  /// An icon image for select group.
  static let selectGroup = Wrapped("custom.group.select", bundle: .module)
  /// An icon image for delete.
  static let delete = Wrapped(systemName: "trash")
  /// An icon image for edit text.
  static let editText = Wrapped(systemName: "keyboard")
  /// An icon image for format text.
  static let formatText = Wrapped(systemName: "textformat.alt")
  /// An icon image for shape.
  static let shape = Wrapped(systemName: "square.on.circle")

  /// An icon image for undo.
  static let undo = Wrapped(systemName: "arrow.uturn.backward.circle")
  /// An icon image for redo.
  static let redo = Wrapped(systemName: "arrow.uturn.forward.circle")
  /// An icon image for export.
  static let export = Wrapped(systemName: "square.and.arrow.up")
  /// An icon image for toggling preview mode.
  static let preview = Wrapped(systemName: "eye")
  /// An icon image for toggling pages mode.
  static let pages = Wrapped(systemName: "doc.on.doc")

  /// An icon image for bring forward.
  static let bringForward = Wrapped(systemName: "square.2.stack.3d.top.fill")
  /// An icon image for send backward.
  static let sendBackward = Wrapped(systemName: "square.2.stack.3d.bottom.fill")
}
