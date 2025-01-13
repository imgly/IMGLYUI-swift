import SwiftUI
@_spi(Internal) import IMGLYCore

struct DockView: View {
  // Interactor is not used directly (except error alert) but keep it to receive all updates to refresh dock on various
  // conditions.
  @EnvironmentObject private var interactor: Interactor

  let dock: EditorContext.To<[any Dock.Item]>
  let context: EditorContext

  var items: [any Dock.Item] {
    do {
      return try dock(context).filter {
        try $0.isVisible(context)
      }
    } catch {
      let error = Error(errorDescription:
        "Could not create View for Dock.\nReason:\n\(error.localizedDescription)")
      interactor.handleErrorWithTask(error)
      return []
    }
  }

  var body: some View {
    let items = items
    ForEach(items, id: \.id) { item in
      AnyView(item.nonThrowingBody(context))
    }
    .preference(key: DockHiddenKey.self, value: items.isEmpty)
  }
}

struct DockHiddenKey: PreferenceKey {
  static let defaultValue: Bool = true
  static func reduce(value: inout Bool, nextValue: () -> Bool) {
    value = value || nextValue()
  }
}
