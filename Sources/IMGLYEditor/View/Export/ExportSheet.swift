import SwiftUI

struct ExportSheet: ViewModifier {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: $interactor.export.isPresented) {
        switch interactor.export.state {
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
        if let state = interactor.export.state {
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
