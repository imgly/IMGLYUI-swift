import SwiftUI
@_spi(Internal) import IMGLYCoreUI

enum SheetMode: Labelable, IdentifiableByHash {
  case add, replace, edit, format, options, crop, fillAndStroke, layer, enterGroup, selectGroup, filter, adjustments,
       effect, blur
  case openCamera, openPhotoRoll, openBackgroundClipLibrary, openOverlayLibrary, addText, addSticker, addAudio
  case selectionColors
  case font(_ id: Interactor.BlockID?, _ fontFamilies: [String]?)
  case fontSize(_ id: Interactor.BlockID?)
  case color(_ id: Interactor.BlockID?, _ colorPalette: [NamedColor]?)
  case reorder, split, volume, delete, duplicate
  case attachToBackground, detachFromBackground

  var pinnedBlockID: Interactor.BlockID? {
    switch self {
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
    case .options: return "Options"
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
    case .openCamera: return "Camera"
    case .openPhotoRoll: return "Photo Roll"
    case .openBackgroundClipLibrary: return "Clip"
    case .openOverlayLibrary: return "Overlay"
    case .addText: return "Text"
    case .addSticker: return "Sticker"
    case .addAudio: return "Audio"
    }
  }

  var imageName: String? {
    switch self {
    case .add: return "plus"
    case .replace: return "arrow.left.arrow.right.square"
    case .edit: return "keyboard"
    case .format: return "textformat.alt"
    case .options: return "slider.horizontal.below.rectangle"
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

    case .openCamera: return "custom.camera.fill.badge.plus"
    case .openPhotoRoll: return "custom.photo.fill.on.rectangle.fill.badge.plus"
    case .openBackgroundClipLibrary: return "custom.add.clip"
    case .openOverlayLibrary: return "custom.film.stack.badge.plus"
    case .addText: return "custom.textformat.alt.badge.plus"
    case .addSticker: return "custom.face.smiling.badge.plus"
    case .addAudio: return "custom.audio.badge.plus"
    }
  }

  var isSystemImage: Bool {
    switch self {
    case .enterGroup, .selectGroup, .attachToBackground, .detachFromBackground, .openCamera, .openPhotoRoll,
         .openBackgroundClipLibrary, .openOverlayLibrary, .addText, .addSticker, .addAudio:
      return false
    default:
      return true
    }
  }

  @MainActor
  func localizedStringKey(_ id: Interactor.BlockID?, _ interactor: Interactor) -> LocalizedStringKey {
    switch self {
    case .fillAndStroke:
      var title = [String]()
      if interactor.hasColorFill(id) {
        title.append("Fill")
      }
      if interactor.hasStroke(id) {
        title.append("Stroke")
      }
      return LocalizedStringKey(title.joined(separator: " & "))
    default: return localizedStringKey
    }
  }

  @MainActor
  @ViewBuilder func label(_ id: Interactor.BlockID?, _ interactor: Interactor) -> some View {
    switch self {
    case .fillAndStroke:
      Label {
        Text(localizedStringKey(id, interactor))
      } icon: {
        switch (interactor.hasColorFill(id), interactor.hasStroke(id)) {
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
    default: label
    }
  }
}
