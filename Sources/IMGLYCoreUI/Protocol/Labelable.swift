import SwiftUI

@_spi(Internal) public protocol Labelable: Localizable, Hashable {
  var imageName: String? { get }
  var isSystemImage: Bool { get }

  /// Enable to align the baseline of the icon with the title or with other icons.
  var isIconEmbeddedInText: Bool { get }
}

@_spi(Internal) public extension Labelable {
  var isSystemImage: Bool { true }
  var isIconEmbeddedInText: Bool { false }

  @ViewBuilder var label: some View {
    if let imageName {
      if isSystemImage {
        Label {
          Text(localizedStringResource)
        } icon: {
          if isIconEmbeddedInText {
            Text(Image(systemName: imageName))
          } else {
            Image(systemName: imageName)
          }
        }
        .symbolRenderingMode(.monochrome)
      } else {
        Label {
          Text(localizedStringResource)
        } icon: {
          if isIconEmbeddedInText {
            Text(Image(imageName, bundle: .module))
          } else {
            Image(imageName, bundle: .module)
          }
        }
      }
    } else {
      Text(localizedStringResource)
    }
  }

  @ViewBuilder var taggedLabel: some View {
    label.tag(self)
  }
}
