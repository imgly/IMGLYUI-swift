@_spi(Internal) import IMGLYCore
import SwiftUI

struct FillStrokeOptionsSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var title: LocalizedStringKey {
    var title = [String]()
    if interactor.isColorFill(id), interactor.supportsFill(id), interactor.isAllowed(id, scope: .fillChange) {
      title.append("Fill")
    }
    if interactor.supportsStroke(id), interactor.isAllowed(id, scope: .strokeChange) {
      title.append("Stroke")
    }
    return LocalizedStringKey(title.joined(separator: " & "))
  }

  var body: some View {
    DismissableTitledSheet(title) {
      FillAndStrokeOptions()
    }
  }
}
