import SwiftUI

@_spi(Internal) public struct GridItemBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  @_spi(Internal) public init() {}

  private var gradientColors: [Color] {
    var colors: [Color] = [.init(uiColor: .quaternarySystemFill),
                           .init(uiColor: .systemFill)]
    if colorScheme == .dark {
      colors.reverse()
    }
    return colors
  }

  @_spi(Internal) public var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(.linearGradient(.init(colors: gradientColors),
                            startPoint: .top, endPoint: .bottom))
  }
}

struct GridItemBackground_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
