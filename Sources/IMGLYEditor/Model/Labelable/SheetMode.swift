import SwiftUI
@_spi(Internal) import IMGLYCoreUI

enum SheetMode: Labelable, IdentifiableByHash {
  case add, replace, edit, format, shape, fillAndStroke, layer, enterGroup, selectGroup

  case adjustments(_ id: Interactor.BlockID? = nil)
  case filter(_ id: Interactor.BlockID? = nil)
  case effect(_ id: Interactor.BlockID? = nil)
  case blur(_ id: Interactor.BlockID? = nil)
  case crop(
    _ id: Interactor.BlockID? = nil,
    _ enter: RootBottomBarItem.Action? = nil,
    _ exit: RootBottomBarItem.Action? = nil
  )

  case addElements
  case addFromPhotoRoll
  case addFromCamera(_ systemCamera: Bool)
  case addClip, addOverlay, addImage, addText, addShape, addSticker, addStickerOrShape, addAudio

  case editPage
  case addPage
  case addVoiceOver, editVoiceOver
  case moveUp
  case moveDown

  case selectionColors
  case font(_ id: Interactor.BlockID?, _ fontFamilies: [String]?)
  case fontSize(_ id: Interactor.BlockID?)
  case color(_ id: Interactor.BlockID?, _ colorPalette: [NamedColor]?)
  case reorder, split, volume, delete, duplicate
  case attachToBackground, detachFromBackground

  var pinnedBlockID: Interactor.BlockID? {
    switch self {
    case let .adjustments(id): return id
    case let .filter(id): return id
    case let .effect(id): return id
    case let .blur(id): return id
    case let .crop(id, _, _): return id
    case let .font(id, _): return id
    case let .fontSize(id): return id
    case let .color(id, _): return id
    default: return nil
    }
  }

  var fontFamilies: [String]? {
    switch self {
    case let .font(_, families): return families
    default: return nil
    }
  }

  var colorPalette: [NamedColor]? {
    switch self {
    case let .color(_, palette): return palette
    default: return nil
    }
  }

  var description: String {
    switch self {
    case .add: return "Add"
    case .replace: return "Replace"
    case .edit: return "Edit"
    case .format: return "Format"
    case .shape: return "Shape"
    case .crop: return "Crop"
    case .fillAndStroke: return "Fill & Stroke"
    case .layer: return "Layer"
    case .enterGroup: return "Enter Group"
    case .selectGroup: return "Select Group"
    case .selectionColors: return "Colors"
    case .font: return "Font"
    case .fontSize: return "Size"
    case .color: return "Color"
    case .filter: return "Filter"
    case .adjustments: return "Adjustments"
    case .effect: return "Effect"
    case .blur: return "Blur"
    case .reorder: return "Reorder"
    case .split: return "Split"
    case .volume: return "Volume"
    case .delete: return "Delete"
    case .duplicate: return "Duplicate"
    case .attachToBackground: return "As Clip"
    case .detachFromBackground: return "As Overlay"

    case .editPage: return "Edit"
    case .addPage: return "Add Page"
    case .moveUp: return "Move Up"
    case .moveDown: return "Move Down"

    case .addElements: return "Elements"
    case .addFromPhotoRoll: return "Photo Roll"
    case .addFromCamera: return "Camera"
    case .addClip: return "Clip"
    case .addOverlay: return "Overlay"
    case .addImage: return "Image"
    case .addText: return "Text"
    case .addShape: return "Shape"
    case .addSticker, .addStickerOrShape: return "Sticker"
    case .addAudio: return "Audio"
    case .addVoiceOver: return "Voiceover"
    case .editVoiceOver: return "Edit"
    }
  }

  var imageName: String? {
    switch self {
    case .add: return "plus"
    case .replace: return "arrow.left.arrow.right.square"
    case .edit: return "keyboard"
    case .format: return "textformat.alt"
    case .shape: return "square.on.circle"
    case .crop: return "crop.rotate"
    case .fillAndStroke: return nil
    case .layer: return "square.3.stack.3d"
    case .enterGroup: return "enter_group"
    case .selectGroup: return "select_group"
    case .adjustments: return "slider.horizontal.3"
    case .filter: return "camera.filters"
    case .effect: return "fx"
    case .blur: return "aqi.medium"
    case .selectionColors, .font, .fontSize, .color: return nil
    case .reorder: return "rectangle.portrait.arrowtriangle.2.outward"
    case .split: return "square.and.line.vertical.and.square"
    case .volume: return "speaker.wave.3.fill"
    case .delete: return "trash"
    case .duplicate: return "plus.square.on.square"
    case .attachToBackground: return "custom.as.clip"
    case .detachFromBackground: return "custom.as.overlay"

    case .editPage: return "square.and.pencil"
    case .addPage: return "custom.doc.badge.plus"
    case .moveUp: return "arrow.up.doc"
    case .moveDown: return "arrow.down.doc"

    case .addElements: return "custom.books.vertical.badge.plus"
    case .addFromPhotoRoll, .addFromCamera: return nil
    case .addClip: return "custom.add.clip"
    case .addOverlay: return "custom.film.stack.badge.plus"
    case .addImage: return "custom.photo.badge.plus"
    case .addText: return "custom.textformat.alt.badge.plus"
    case .addShape: return "custom.square.on.circle.badge.plus"
    case .addSticker, .addStickerOrShape: return "custom.face.smiling.badge.plus"
    case .addAudio: return "custom.audio.badge.plus"
    case .addVoiceOver: return "custom.mic.badge.plus"
    case .editVoiceOver: return "custom.waveform.badge.mic"
    }
  }

  var isSystemImage: Bool {
    guard let imageName else {
      return true
    }
    return !imageName.hasPrefix("custom.")
  }

  @MainActor
  func localizedStringKey(_ id: Interactor.BlockID?, _ interactor: Interactor) -> LocalizedStringKey {
    switch self {
    case .fillAndStroke:
      var title = [String]()
      if interactor.isColorFill(id) {
        title.append("Fill")
      }
      if interactor.supportsStroke(id) {
        title.append("Stroke")
      }
      return LocalizedStringKey(title.joined(separator: " & "))
    default: return localizedStringKey
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  @MainActor @ViewBuilder func label(_ id: Interactor.BlockID?, _ interactor: Interactor) -> some View {
    switch self {
    case .fillAndStroke:
      Label {
        Text(localizedStringKey(id, interactor))
      } icon: {
        switch (interactor.isColorFill(id), interactor.supportsStroke(id)) {
        case (true, true):
          AdaptiveOverlay {
            FillColorIcon()
          } overlay: {
            StrokeColorIcon()
          }
        case (true, false):
          FillColorIcon()
        case (false, true):
          StrokeColorIcon()
        case (false, false):
          EmptyView()
        }
      }
    case .selectionColors:
      Label {
        Text(localizedStringKey)
      } icon: {
        SelectionColorsIcon()
      }
    case .font:
      Label {
        Text(localizedStringKey)
      } icon: {
        FontIcon()
      }
    case .fontSize:
      Label {
        Text(localizedStringKey)
      } icon: {
        FontSizeIcon()
      }
    case .color:
      Label {
        Text(localizedStringKey)
      } icon: {
        FillColorIcon()
      }
    case .addFromCamera:
      Label {
        Text(localizedStringKey)
      } icon: {
        Image(
          interactor.sceneMode == .video ? "custom.camera.fill.badge.plus" :
            "custom.camera.badge.plus",
          bundle: .module
        )
      }
    case .addFromPhotoRoll:
      Label {
        Text(localizedStringKey)
      } icon: {
        Image(
          interactor.sceneMode == .video ? "custom.photo.fill.on.rectangle.fill.badge.plus" :
            "custom.photo.on.rectangle.badge.plus",
          bundle: .module
        )
      }
    default: label
    }
  }
}
