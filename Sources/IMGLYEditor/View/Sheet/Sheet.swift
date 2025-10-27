@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct Sheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.colorScheme) private var colorScheme
  private var sheet: SheetState { interactor.sheet }

  @Environment(\.verticalSizeClass) private var verticalSizeClass

  @ViewBuilder func sheet(_ mode: SheetMode) -> some View {
    switch mode {
    case .resize: ResizeOptionsSheet()
    default: EmptyView()
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  @ViewBuilder func sheet(_ type: SheetType) -> some View {
    switch type {
    case let sheet as SheetTypes.Custom:
      AnyView(erasing: sheet.content())
    case let sheet as SheetTypes.LibraryAdd:
      AnyView(erasing: sheet.content())
    case let sheet as SheetTypes.LibraryReplace:
      AnyView(erasing: sheet.content())
        .imgly.assetLibrary(titleDisplayMode: .inline)
    case let sheet as SheetTypes.GreetingColors:
      ColorSheet()
        .imgly.selection(sheet.id)
        .imgly.colorPalette(sheet.colorPalette)
    case let sheet as SheetTypes.GreetingFont:
      FontSheet()
        .imgly.selection(sheet.id)
        .imgly.fontFamilies(sheet.fontFamilies)
    case let sheet as SheetTypes.Crop:
      CropOptionsSheet(sources: sheet.assetSourceIDs)
    case is SheetTypes.Voiceover: VoiceoverSheet()
    case is SheetTypes.Reorder: ReorderOptionsSheet()
    case is SheetTypes.Adjustments: AdjustmentsOptionsSheet()
    case is SheetTypes.Filter: FilterOptionsSheet()
    case is SheetTypes.Effect: EffectOptionsSheet()
    case is SheetTypes.Blur: BlurOptionsSheet()
    case is SheetTypes.Layer: LayerOptionsSheet()
    case is SheetTypes.FormatText: FormatTextOptionsSheet()
    case is SheetTypes.Shape: ShapeOptionsSheet()
    case is SheetTypes.FillStroke: FillStrokeOptionsSheet()
    case is SheetTypes.TextBackground: BackgroundOptionsSheet()
    case is SheetTypes.Volume: VolumeOptionsSheet()
    case is SheetTypes.Resize: ResizeOptionsSheet()
    case is SheetTypes.DesignColors: SelectionColorsSheet()
    case is SheetTypes.GreetingSize: FontSizeSheet()
    default: EmptyView()
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

  var body: some View {
    Group {
      if let type = sheet.type {
        if let type = type as? SheetTypeForDesignBlock {
          sheet(type).imgly.selection(type.id)
        } else {
          sheet(type)
        }
      } else if let mode = sheet.mode {
        sheet(mode)
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
    .imgly.presentationConfiguration(sheet.style.largestUndimmedDetent)
    .presentationDetents(sheet.style.detents, selection: $interactor.sheet.style.detent)
    .presentationDragIndicator(dragIndicatorVisibility)
    .preferredColorScheme(colorScheme)
  }
}

struct Sheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.libraryAdd {
      AssetLibrarySheet(content: .image)
    }, .image))
  }
}
