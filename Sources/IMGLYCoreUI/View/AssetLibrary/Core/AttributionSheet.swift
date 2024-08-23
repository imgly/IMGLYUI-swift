@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

struct AttributionSheet: ViewModifier {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  let asset: AssetLoader.Asset

  var assetCredits: AttributedString? { asset.result.credits?.link }
  var assetLicense: AttributedString? { asset.result.license?.link }
  var sourceCredits: AttributedString? { interactor.getCredits(sourceID: asset.sourceID)?.link }
  var sourceLicense: AttributedString? { interactor.getLicense(sourceID: asset.sourceID)?.link }

  @State private var showAttribution = false

  func body(content: Content) -> some View {
    content
      .imgly.delayedGesture(LongPressGesture().onEnded { _ in
        if assetLicense != nil || sourceLicense != nil {
          showAttribution = true
        }
      })
      .sheet(isPresented: $showAttribution) {
        Attribution(asset: asset,
                    assetCredits: assetCredits, assetLicense: assetLicense,
                    sourceCredits: sourceCredits, sourceLicense: sourceLicense)
      }
  }
}

private struct Attribution: View {
  @Environment(\.dismiss) var dismiss

  let asset: AssetLoader.Asset
  let assetCredits, assetLicense, sourceCredits, sourceLicense: AttributedString?

  var label: String? {
    asset.result.label ?? asset.result.filename ?? asset.result.id
  }

  var credits: LocalizedStringKey? {
    if let assetCredits, let sourceCredits {
      .init("By \(assetCredits) on \(sourceCredits)")
    } else if let assetCredits {
      .init("By \(assetCredits)")
    } else if let sourceCredits {
      .init("On \(sourceCredits)")
    } else {
      nil
    }
  }

  var license: LocalizedStringKey? {
    if let assetLicense {
      .init("\(assetLicense)")
    } else if let sourceLicense {
      .init("\(sourceLicense)")
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
      .navigationTitle("Details")
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
