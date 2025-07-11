@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

struct AttributionSheet: ViewModifier {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  let asset: AssetLoader.Asset
  let onShowAttribution: () -> Void

  var assetLicense: AttributedString? { asset.result.license?.link }
  var sourceLicense: AttributedString? { interactor.getLicense(sourceID: asset.sourceID)?.link }

  func body(content: Content) -> some View {
    content
      .onLongPressGesture {
        if assetLicense != nil || sourceLicense != nil {
          onShowAttribution()
        }
      }
  }
}

struct Attribution: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  @Environment(\.dismiss) var dismiss
  @Environment(\.colorScheme) private var colorScheme

  let asset: AssetLoader.Asset

  var assetCredits: AttributedString? { asset.result.credits?.link }
  var assetLicense: AttributedString? { asset.result.license?.link }
  var sourceCredits: AttributedString? { interactor.getCredits(sourceID: asset.sourceID)?.link }
  var sourceLicense: AttributedString? { interactor.getLicense(sourceID: asset.sourceID)?.link }

  var label: String? {
    asset.result.label ?? asset.result.filename ?? asset.result.id
  }

  var credits: LocalizedStringResource? {
    if let assetCredits, let sourceCredits {
      .imgly.localized("ly_img_editor_asset_library_label_credits_artist_on_source \(assetCredits) \(sourceCredits)")
    } else if let assetCredits {
      .imgly.localized("ly_img_editor_asset_library_label_credits_artist \(assetCredits)")
    } else if let sourceCredits {
      .imgly.localized("ly_img_editor_asset_library_label_credits_on_source \(sourceCredits)")
    } else {
      nil
    }
  }

  var license: AttributedString? {
    if let assetLicense {
      assetLicense
    } else if let sourceLicense {
      sourceLicense
    } else {
      nil
    }
  }

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          if let label {
            Text(label)
              .padding(.bottom, 12)
          }
          if let credits {
            Text(credits)
              .font(.footnote)
              .padding(.bottom, 10)
          }
          if let license {
            Divider()
              .padding(.bottom, 10)
            Text(license)
              .font(.footnote)
          }
        }
        .padding([.leading, .trailing], 16)
      }
      .navigationTitle(Text(.imgly.localized("ly_img_editor_asset_library_title_credits")))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            dismiss()
          } label: {
            Label("Close", systemImage: "xmark.circle.fill")
              .symbolRenderingMode(.hierarchical)
              .foregroundColor(.secondary)
              .font(.title2)
          }
          .buttonStyle(.borderless)
        }
      }
    }
    .navigationViewStyle(.stack)
    .presentationDetents([.custom(AttributionPresentationDetent.self)])
    .preferredColorScheme(colorScheme)
  }
}

private protocol AttributionLink {
  var name: String { get }
  var url: URL? { get }

  var isEmpty: Bool { get }
  var link: AttributedString? { get }
}

private extension AttributionLink {
  var isEmpty: Bool {
    name.isEmpty && url?.absoluteString.isEmpty ?? true
  }

  var link: AttributedString? {
    guard !isEmpty else {
      return nil
    }

    if let url {
      let text = name.isEmpty ? url.absoluteString : name
      var string = AttributedString(text)
      string.link = url
      string.underlineStyle = .single
      string.foregroundColor = .primary
      return string
    } else {
      return .init(name)
    }
  }
}

extension AssetCredits: AttributionLink {}
extension AssetLicense: AttributionLink {}

private struct AttributionPresentationDetent: CustomPresentationDetent {
  static func height(in context: Context) -> CGFloat? {
    if context.verticalSizeClass == .compact {
      160
    } else {
      280
    }
  }
}

struct AttributionSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
