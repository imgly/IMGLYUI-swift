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

  static let reorder = Wrapped(systemName: "rectangle.portrait.arrowtriangle.2.outward")
  static let adjustments = Wrapped(systemName: "slider.horizontal.3")
  static let filter = Wrapped(systemName: "camera.filters")
  static let effect = Wrapped(systemName: "fx")
  static let blur = Wrapped(systemName: "aqi.medium")
  static let crop = Wrapped(systemName: "crop.rotate")
}
