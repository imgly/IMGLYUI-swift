import IMGLYCore
import SwiftUI

extension Image: IMGLYCompatible {}

@_spi(Unstable) public extension IMGLY where Wrapped == Image {
  static let addElement = Wrapped("custom.books.vertical.badge.plus", bundle: .module)
  static let addVideo = Wrapped("custom.film.stack.badge.plus", bundle: .module)
  static let addAudio = Wrapped("custom.audio.badge.plus", bundle: .module)
  static let addImage = Wrapped("custom.photo.badge.plus", bundle: .module)
  static let addText = Wrapped("custom.textformat.alt.badge.plus", bundle: .module)
  static let addShape = Wrapped("custom.square.on.circle.badge.plus", bundle: .module)
  static let addSticker = Wrapped("custom.face.smiling.badge.plus", bundle: .module)

  static let addPhotoRollBackground = Wrapped("custom.photo.fill.on.rectangle.fill.badge.plus", bundle: .module)
  static let addPhotoRollForeground = Wrapped("custom.photo.on.rectangle.badge.plus", bundle: .module)
  static let addCameraBackground = Wrapped("custom.camera.fill.badge.plus", bundle: .module)
  static let addCameraForeground = Wrapped("custom.camera.badge.plus", bundle: .module)
  static let addVoiceover = Wrapped("custom.mic.badge.plus", bundle: .module)

  static let editVoiceover = Wrapped("custom.waveform.badge.mic", bundle: .module)

  static let reorder = Wrapped(systemName: "rectangle.portrait.arrowtriangle.2.outward")
  static let adjustments = Wrapped(systemName: "slider.horizontal.3")
  static let filter = Wrapped(systemName: "camera.filters")
  static let effect = Wrapped(systemName: "fx")
  static let blur = Wrapped(systemName: "aqi.medium")
  static let volume = Wrapped(systemName: "speaker.wave.3.fill")
  static let crop = Wrapped(systemName: "crop.rotate")

  static let duplicate = Wrapped(systemName: "plus.square.on.square")
  static let layer = Wrapped(systemName: "square.3.stack.3d")
  static let split = Wrapped(systemName: "square.and.line.vertical.and.square")
  static let moveAsClip = Wrapped("custom.as.clip", bundle: .module)
  static let moveAsOverlay = Wrapped("custom.as.overlay", bundle: .module)
  static let replace = Wrapped(systemName: "arrow.left.arrow.right.square")
  static let enterGroup = Wrapped("enter_group", bundle: .module)
  static let selectGroup = Wrapped("select_group", bundle: .module)
  static let delete = Wrapped(systemName: "trash")
  static let editText = Wrapped(systemName: "keyboard")
  static let formatText = Wrapped(systemName: "textformat.alt")
  static let shape = Wrapped(systemName: "square.on.circle")
}
