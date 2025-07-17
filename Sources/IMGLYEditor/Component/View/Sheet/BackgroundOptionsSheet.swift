@_spi(Internal) import IMGLYCore
import SwiftUI

struct BackgroundOptionsSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    DismissableTitledSheet("Background") {
      BackgroundOptions(isEnabled: interactor.bind(id,
                                                   property: .key(.backgroundColorEnabled),
                                                   default: false))
    }
  }
}
