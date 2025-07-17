import SwiftUI

@_spi(Internal) public protocol Labelable: Localizable, Hashable {
  var imageName: String? { get }
  var isSystemImage: Bool { get }
}

@_spi(Internal) public extension Labelable {
  var isSystemImage: Bool { true }

  @ViewBuilder var label: some View {
    label(suffix: nil)
  }

  @ViewBuilder func label(suffix: String?) -> some View {
    if let imageName {
      if isSystemImage {
        Label(localizedStringKey(suffix: suffix), systemImage: imageName)
          .symbolRenderingMode(.monochrome)
      } else {
        Label {
          Text(localizedStringKey(suffix: suffix))
        } icon: {
          Image(imageName, bundle: .module)
        }
      }
    } else {
      Text(localizedStringKey(suffix: suffix))
    }
  }

  @ViewBuilder var taggedLabel: some View {
    taggedLabel(suffix: nil)
  }

  @ViewBuilder func taggedLabel(suffix: String?) -> some View {
    label(suffix: suffix).tag(self)
  }
}
