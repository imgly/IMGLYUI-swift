@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct SelectableAssetItem<Content: View>: View {
  @ViewBuilder let content: Content
  let title: String
  let selected: Bool
  let properties: [EffectProperty]
  let asset: AssetLoader.Asset
  @Binding var sheetState: EffectSheetState

  @EnvironmentObject private var interactor: Interactor

  private var localizedTitle: LocalizedStringKey {
    .init(title)
  }

  private var image: Image {
    if #available(iOS 17.0, *) {
      Image(systemName: "slider.horizontal.2.square")
    } else {
      Image("custom.slider.horizontal.2.square", bundle: .module)
    }
  }

  @ViewBuilder var overlay: some View {
    ZStack {
      Color.black.opacity(0.5)
      image
        .foregroundColor(.white)
        .font(.largeTitle)
    }
    .onTapGesture {
      let propertyState = AssetProperties(title: localizedTitle, backTitle: "Back", properties: properties)
      sheetState = .properties(propertyState)
      var detent = PresentationDetent.adaptiveTiny
      var detents: Set<PresentationDetent> = [detent]
      if properties.count > 1 {
        detent = .adaptiveMedium
        detents.insert(.adaptiveMedium)
      }
      interactor.sheet.commit { model in
        model = .init(model.mode, model.type)
        model.detents = detents
        model.detent = detent
      }
    }
  }

  var body: some View {
    SelectableEffectItem(title: localizedTitle, selected: selected) {
      ZStack {
        content
        overlay
          .opacity((selected && !properties.isEmpty) ? 1 : 0)
      }
    }
  }
}
