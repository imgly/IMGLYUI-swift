@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct SelectableAssetItem<Content: View>: View {
  @ViewBuilder let content: Content
  let title: String
  let selected: Bool
  let properties: [EffectProperty]
  let asset: AssetLoader.Asset
  @Binding var sheetState: EffectSheetState
  /// Set when the properties page is custom instead of derived from `properties`, which may then be empty.
  var hasCustomProperties = false

  @EnvironmentObject private var interactor: Interactor

  // Since we still don't support localization in asset sources, this allows customers to localize titles directly
  private var localizedTitle: String {
    String(localized: LocalizedStringResource(stringLiteral: title))
  }

  private var showsProperties: Bool {
    hasCustomProperties || !properties.isEmpty
  }

  private var image: Image {
    if #available(iOS 17.0, *) {
      Image(systemName: "slider.horizontal.2.square")
    } else {
      Image("custom.slider.horizontal.2.square", bundle: .module)
    }
  }

  var overlay: some View {
    ZStack {
      Color.black.opacity(0.5)
      image
        .foregroundColor(.white)
        .font(.largeTitle)
    }
    .onTapGesture {
      let currentStyle = interactor.sheet.style
      let propertyState = AssetProperties(
        title: localizedTitle,
        backTitle: .imgly.localized("ly_img_editor_sheet_button_back"),
        properties: properties,
        previousStyle: currentStyle,
      )
      sheetState = .properties(propertyState)
      var detent = PresentationDetent.imgly.tiny
      var detents: Set<PresentationDetent> = [detent]
      if properties.count > 1 || hasCustomProperties {
        detent = .imgly.medium
        detents.insert(.imgly.medium)
      }
      interactor.sheet.commit { model in
        model.style = currentStyle.resized(detent: detent, detents: detents)
      }
    }
  }

  var body: some View {
    SelectableEffectItem(title: localizedTitle, selected: selected) {
      ZStack {
        content
        overlay
          .opacity((selected && showsProperties) ? 1 : 0)
          .allowsHitTesting(selected && showsProperties)
      }
    }
  }
}
