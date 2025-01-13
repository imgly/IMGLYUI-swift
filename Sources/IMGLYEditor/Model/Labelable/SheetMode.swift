import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct PseudoHashable<T>: Hashable {
  static func == (_: Self, _: Self) -> Bool {
    true
  }

  func hash(into _: inout Hasher) {}

  let value: T
}

typealias PseudoHashableAction = PseudoHashable < () throws -> Void>
typealias PseudoHashableViewBuilder = PseudoHashable<() -> AnyView>

enum SheetMode: Labelable, IdentifiableByHash {
  case add, replace, edit, format, shape, fillAndStroke, layer, enterGroup, selectGroup

  case adjustments(_ id: Interactor.BlockID? = nil)
  case filter(_ id: Interactor.BlockID? = nil)
  case effect(_ id: Interactor.BlockID? = nil)
  case blur(_ id: Interactor.BlockID? = nil)
  case crop(
    _ id: Interactor.BlockID? = nil,
    enter: PseudoHashableAction? = nil,
    exit: PseudoHashableAction? = nil
  )

  case sheet(_ view: PseudoHashableViewBuilder)

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
    case let .adjustments(id): id
    case let .filter(id): id
    case let .effect(id): id
    case let .blur(id): id
    case let .crop(id, _, _): id
    case let .font(id, _): id
    case let .fontSize(id): id
    case let .color(id, _): id
    default: nil
    }
  }

  var fontFamilies: [String]? {
    switch self {
    case let .font(_, families): families
    default: nil
    }
  }

  var colorPalette: [NamedColor]? {
    switch self {
    case let .color(_, palette): palette
    default: nil
    }
  }

  var description: String {
    switch self {
    case .sheet: "Sheet"
    case .add: "Add"
    case .replace: "Replace"
    case .edit: "Edit"
    case .format: "Format"
    case .shape: "Shape"
    case .crop: "Crop"
    case .fillAndStroke: "Fill & Stroke"
    case .layer: "Layer"
    case .enterGroup: "Enter Group"
    case .selectGroup: "Select Group"
    case .selectionColors: "Colors"
    case .font: "Font"
    case .fontSize: "Size"
    case .color: "Color"
    case .filter: "Filter"
    case .adjustments: "Adjustments"
    case .effect: "Effect"
    case .blur: "Blur"
    case .reorder: "Reorder"
    case .split: "Split"
    case .volume: "Volume"
    case .delete: "Delete"
    case .duplicate: "Duplicate"
    case .attachToBackground: "As Clip"
    case .detachFromBackground: "As Overlay"
    case .editPage: "Edit"
    case .addPage: "Add Page"
    case .moveUp: "Move Up"
    case .moveDown: "Move Down"
    case .addVoiceOver: "Voiceover"
    case .editVoiceOver: "Edit"
    }
  }

  var imageName: String? {
    switch self {
    case .sheet: "document"
    case .add: "plus"
    case .replace: "arrow.left.arrow.right.square"
    case .edit: "keyboard"
    case .format: "textformat.alt"
    case .shape: "square.on.circle"
    case .crop: "crop.rotate"
    case .fillAndStroke: nil
    case .layer: "square.3.stack.3d"
    case .enterGroup: "enter_group"
    case .selectGroup: "select_group"
    case .adjustments: "slider.horizontal.3"
    case .filter: "camera.filters"
    case .effect: "fx"
    case .blur: "aqi.medium"
    case .selectionColors, .font, .fontSize, .color: nil
    case .reorder: "rectangle.portrait.arrowtriangle.2.outward"
    case .split: "square.and.line.vertical.and.square"
    case .volume: "speaker.wave.3.fill"
    case .delete: "trash"
    case .duplicate: "plus.square.on.square"
    case .attachToBackground: "custom.as.clip"
    case .detachFromBackground: "custom.as.overlay"
    case .editPage: "square.and.pencil"
    case .addPage: "custom.doc.badge.plus"
    case .moveUp: "arrow.up.doc"
    case .moveDown: "arrow.down.doc"
    case .addVoiceOver: nil
    case .editVoiceOver: "custom.waveform.badge.mic"
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
    default: label
    }
  }
}
