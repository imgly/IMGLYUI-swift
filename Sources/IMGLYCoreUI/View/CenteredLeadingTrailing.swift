import SwiftUI

/// The centered view stays put while the leading and trailing views expand and shrink.
@_spi(Internal) public struct CenteredLeadingTrailing<Centered: View, Leading: View, Trailing: View>: View {
  let centered: Centered
  let leading: Leading
  let trailing: Trailing

  @_spi(Internal) public init(
    @ViewBuilder centered: () -> Centered,
    @ViewBuilder leading: () -> Leading,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.leading = leading()
    self.centered = centered()
    self.trailing = trailing()
  }

  @_spi(Internal) public var body: some View {
    HStack {
      HStack {
        leading
      }
      .frame(maxWidth: .infinity)

      centered

      HStack {
        trailing
      }
      .frame(maxWidth: .infinity)
    }
  }
}

struct CenteredLeadingTrailing_Previews: PreviewProvider {
  static var previews: some View {
    CenteredLeadingTrailing {
      Text("Centered")
    } leading: {
      Text("Ldng")
    } trailing: {
      Text("Trailinggggggggggggggggg")
    }
  }
}
