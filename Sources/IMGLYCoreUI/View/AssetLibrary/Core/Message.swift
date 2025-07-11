import SwiftUI

/// A message view used in the ``AssetLibrary``.
public struct Message: View {
  /// No elements message.
  public static let noElements = Message(.imgly.localized("ly_img_editor_asset_library_label_empty"))
  /// No service message.
  public static let noService = Message(
    .imgly.localized("ly_img_editor_asset_library_label_error"),
    systemImage: "exclamationmark.triangle"
  )

  private let title: LocalizedStringResource
  private let systemImage: String?
  private let imageFont: Font?

  @Environment(\.imglyAssetGridMessageTextOnly) private var messageTextOnly

  init(_ title: LocalizedStringResource, systemImage: String? = nil, imageFont: Font? = nil) {
    self.title = title
    self.systemImage = systemImage
    self.imageFont = imageFont
  }

  public var body: some View {
    VStack(spacing: 10) {
      if let systemImage, !messageTextOnly {
        Image(systemName: systemImage)
          .font(imageFont)
      }
      Text(title)
    }
    .imageScale(.large)
    .foregroundColor(.secondary)
  }
}

struct Message_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
