import SwiftUI

public struct Message: View {
  public static let noElements = Message("No Elements")
  public static let noService = Message("Cannot Connect to Service", systemImage: "exclamationmark.triangle")

  private let title: LocalizedStringKey
  private let systemImage: String?
  private let imageFont: Font?

  @Environment(\.imglyAssetGridMessageTextOnly) private var messageTextOnly

  init(_ title: LocalizedStringKey, systemImage: String? = nil, imageFont: Font? = nil) {
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
