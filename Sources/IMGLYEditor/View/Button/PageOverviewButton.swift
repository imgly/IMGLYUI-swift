import SwiftUI

@_spi(Internal) public struct PageOverviewButton: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  @_spi(Internal) public init() {}

  @_spi(Internal) public var body: some View {
    Button {
      interactor.isPageOverviewShown.toggle()
    } label: {
      HStack {
        Image(systemName: "doc.on.doc")
          .symbolVariant(interactor.isPageOverviewShown ? .fill : .none)
        Text("\(interactor.pageCount)")
          .monospacedDigit()
          .font(.subheadline.weight(.semibold))
        if verticalSizeClass == .compact {
          Text(interactor.pageCount > 1 ? "Pages" : "Page")
            .padding(.leading, -4)
        }
      }
    }
    .accessibilityLabel(interactor.isPageOverviewShown ? "Hide Pages" : "Show Pages")
    .disabled(interactor.isLoading)
  }
}

struct PageOverviewButton_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
