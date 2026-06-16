import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct TransformItem: View {
  let asset: AssetItem

  var body: some View {
    switch asset {
    case let .asset(asset):
      DynamicTransformItem(asset: asset)
        .accessibilityLabel(asset.labelOrTypefaceName ?? "")
        .accessibilityAddTraits(.isButton)
    case .placeholder:
      GridItemBackground()
        .aspectRatio(1, contentMode: .fit)
    }
  }
}

private struct DynamicTransformItem: View {
  @Environment(\.imglySelection) private var id
  @Environment(\.legibilityWeight) private var legibilityWeight
  @EnvironmentObject private var interactor: Interactor
  @ScaledMetric(relativeTo: .title) private var size: CGFloat = 32

  let asset: AssetLoader.Asset

  private var weight: CGFloat {
    let defaultWidth = legibilityWeight == .bold ? 3 : 2.25
    return defaultWidth * (size / 32)
  }

  var body: some View {
    switch asset.result.payload?.transformPreset {
    case .freeAspectRatio:
      VStack {
        Image(systemName: "square.dashed")
          .frame(width: size, height: size)
          .font(.title)
        Text(asset.labelOrTypefaceName ?? "Unknown")
          .font(.caption2)
          .lineLimit(3)
          .frame(maxWidth: 56)
          .multilineTextAlignment(.center)
      }
      .aspectRatio(1.3, contentMode: .fit)
      .onTapGesture(perform: onTap)
    case let .fixedAspectRatio(width, height):
      VStack {
        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
          .stroke(lineWidth: weight)
          .aspectRatio(CGFloat(width / height), contentMode: .fit)
          .foregroundColor(.primary)
          .padding(5)
          .frame(width: size, height: size)
        Text(asset.labelOrTypefaceName ?? "Unknown")
          .font(.caption2)
          .lineLimit(3)
          .frame(maxWidth: 56)
          .multilineTextAlignment(.center)
      }
      .aspectRatio(1.3, contentMode: .fit)
      .onTapGesture(perform: onTap)
    case .fixedSize:
      VStack {
        ReloadableAsyncImage(asset: asset, content: { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, minHeight: 0)
            .clipped()
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(8)
        }, onTap: onTap)
          .frame(width: 80, height: 80)
        Text(asset.labelOrTypefaceName ?? "Unknown")
          .font(.caption2)
          .lineLimit(3)
          .multilineTextAlignment(.center)
        Spacer()
      }
      .aspectRatio(0.7, contentMode: .fit)
    default:
      EmptyView()
    }
  }

  private func onTap() {
    interactor.applyResizeAsset(sourceID: asset.sourceID, asset: asset.result, to: id)
  }
}
