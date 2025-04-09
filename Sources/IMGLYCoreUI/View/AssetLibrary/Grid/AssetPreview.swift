@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

/// A grid of assets for preview.
public struct AssetPreview: View {
  @Environment(\.imglySeeAllView) private var seeAllView
  private let height: CGFloat?

  /// Creates a grid of assets for preview.
  /// - Parameter height: The height of the frame.
  public init(height: CGFloat?) {
    self.height = height
  }

  @MainActor
  @ViewBuilder func item(_ assetItem: AssetItem) -> some View {
    if case let .asset(asset) = assetItem {
      // If not set assume the default engine value.
      let designBlockType = asset.result.blockType ?? DesignBlockType.graphic.rawValue
      if designBlockType == DesignBlockType.graphic.rawValue {
        let fillType = asset.result.fillType ?? ""
        let designBlockKind = asset.result.blockKind ?? ""

        switch fillType {
        case FillType.video.rawValue:
          if designBlockKind == BlockKind.key(.animatedSticker).rawValue {
            StickerItem(asset: assetItem)
          } else {
            ImageItem(asset: assetItem)
          }
        case FillType.image.rawValue:
          if designBlockKind == BlockKind.key(.sticker).rawValue {
            StickerItem(asset: assetItem)
          } else {
            ImageItem(asset: assetItem)
          }
        case FillType.color.rawValue, FillType.linearGradient.rawValue,
             FillType.radialGradient.rawValue, FillType.conicalGradient.rawValue:
          ShapeItem(asset: assetItem)
        default:
          if designBlockKind == BlockKind.key(.shape).rawValue {
            ShapeItem(asset: assetItem)
          } else {
            ImageItem(asset: assetItem)
          }
        }
      } else {
        ImageItem(asset: assetItem)
      }
    } else {
      ImageItem(asset: assetItem)
    }
  }

  public var body: some View {
    AssetGrid { asset in
      item(asset)
    } empty: { _ in
      Message.noElements
    } more: {
      seeAllView
    }
    .imgly.assetGrid(axis: .horizontal)
    .imgly.assetGrid(items: [GridItem(.adaptive(minimum: 108, maximum: 152), spacing: 4)])
    .imgly.assetGrid(spacing: 4)
    .imgly.assetGrid(edges: [.leading, .trailing])
    .imgly.assetGrid(padding: 16)
    .imgly.assetGrid(maxItemCount: 10)
    .imgly.assetGridPlaceholderCount { _, maxItemCount in
      maxItemCount
    }
    .imgly.assetGrid(messageTextOnly: true)
    .imgly.assetLoader()
    .frame(height: height)
  }
}

struct AssetPreview_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
