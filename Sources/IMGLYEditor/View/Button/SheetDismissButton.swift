import SwiftUI

struct SheetDismissButton: View {
  @EnvironmentObject private var interactor: Interactor

  var body: some View {
    Button {
      interactor.sheetDismissButtonTapped()
    } label: {
      Label("Dismiss", systemImage: "chevron.down.circle.fill")
        .symbolRenderingMode(.hierarchical)
        .foregroundColor(.secondary)
        .font(.title2)
    }
  }
}
