@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct Sheet: View {
  @EnvironmentObject private var interactor: Interactor
  private var sheet: SheetState { interactor.sheet }

  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.imglyAssetLibrary) private var anyAssetLibrary

  // swiftlint:disable:next cyclomatic_complexity
  @ViewBuilder func sheet(_ type: SheetType) -> some View {
    switch type {
    case .image: ImageSheet()
    case .text: TextSheet()
    case .shape: ShapeSheet()
    case .sticker: StickerSheet()
    case .group: GroupSheet()
    case .selectionColors: SelectionColorsSheet()
    case .font: FontSheet()
    case .fontSize: FontSizeSheet()
    case .color: ColorSheet()
    case .page: PageSheet()
    case .video: VideoSheet()
    case .audio: AudioSheet()
    case .voiceover: VoiceOverSheet()
    case .reorder: ReorderSheet()
    case .asset, .elements, .clip, .overlay, .stickerOrShape, .pageOverview: EmptyView()
    }
  }

  @State var hidePresentationDragIndicator: Bool = false

  var dragIndicatorVisibility: Visibility {
    if hidePresentationDragIndicator {
      return .hidden
    }
    if verticalSizeClass == .compact {
      return .hidden
    }
    return .visible
  }

  var assetLibrary: some AssetLibrary {
    anyAssetLibrary ?? AnyAssetLibrary(erasing: DefaultAssetLibrary())
  }

  var body: some View {
    Group {
      switch sheet.mode {
      case .add:
        switch sheet.type {
        case .asset: assetLibrary
        case .elements: assetLibrary.elementsTab
        case .image: assetLibrary.imagesTab
        case .text: assetLibrary.textTab
        case .shape: assetLibrary.shapesTab
        case .sticker: assetLibrary.stickersTab
        case .clip: assetLibrary.clipsTab
        case .overlay: assetLibrary.overlaysTab
        case .stickerOrShape: assetLibrary.stickersAndShapesTab
        case .audio: assetLibrary.audioTab
        default: EmptyView()
        }

      case .replace:
        Group {
          switch sheet.type {
          case .video: assetLibrary.videosTab
          case .audio: assetLibrary.audioTab
          case .image: assetLibrary.imagesTab
          case .sticker: assetLibrary.stickersTab
          default: EmptyView()
          }
        }
        .imgly.assetLibrary(titleDisplayMode: .inline)

      default:
        if let id = sheet.mode.pinnedBlockID {
          sheet(sheet.type)
            .imgly.selection(id)
            .imgly.colorPalette(sheet.mode.colorPalette)
            .imgly.fontFamilies(sheet.mode.fontFamilies)
        } else {
          sheet(sheet.type)
        }
      }
    }
    .imgly.assetLibrary(sceneMode: interactor.sceneMode)
    .imgly.assetLibrary(interactor: interactor)
    .imgly.assetLibraryDismissButton {
      SheetDismissButton()
      // Don't apply .buttonStyle(.borderless)! It breaks asset library search and dismiss button on iOS 17.
    }
    .onPreferenceChange(PresentationDragIndicatorHiddenKey.self) { newValue in
      hidePresentationDragIndicator = newValue
    }
    .pickerStyle(.menu)
    .imgly.presentationConfiguration(sheet.largestUndimmedDetent)
    .presentationDetents(sheet.detents, selection: $interactor.sheet.detent)
    .presentationDragIndicator(dragIndicatorVisibility)
  }
}

struct Sheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.add, .image))
  }
}
