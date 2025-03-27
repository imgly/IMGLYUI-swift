import SwiftUI

struct ExportSheet: ViewModifier {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.colorScheme) private var colorScheme
  @ObservedObject private var exportState: ExportSheetState

  init(exportState: ExportSheetState) {
    self.exportState = exportState
  }

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: $exportState.isPresented) {
        switch exportState.state {
        case .none:
          break
        case .exporting:
          interactor.cancelExport()
        case let .completed(_, action):
          action()
        case let .error(_, action):
          action()
        }
      } content: {
        if let state = exportState.state {
          ExportView(state: state)
            .presentationDetents([.medium])
            .preferredColorScheme(colorScheme)
        }
      }
  }
}

struct ExportSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
