import SwiftUI
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public struct ExportButton: View {
  @EnvironmentObject private var interactor: Interactor

  @_spi(Internal) public init() {}

  @_spi(Internal) public var body: some View {
    ActionButton(.export)
      .disabled(interactor.isLoading || interactor.isExporting)
      .modifier(ExportSheet())
      .modifier(ShareSheet())
  }
}

struct ExportButton_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
