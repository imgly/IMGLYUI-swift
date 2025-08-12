import SwiftUI

struct DockView: View {
  // Interactor is not used directly (except error alert) but keep it to receive all updates to refresh dock on various
  // conditions.
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglyDockModifications) private var modifications

  let items: Dock.Context.To<[any Dock.Item]>
  let context: Dock.Context

  private var _items: [any Dock.Item] {
    do {
      var items = try items(context)
      if let modifications {
        let modifier = Dock.Modifier()
        try modifications(context, modifier)
        try modifier.apply(to: &items)
      }
      return try items.filter {
        try $0.isVisible(context)
      }
    } catch {
      let error = EditorError(
        "Could not create View for Dock.\nReason:\n\(error.localizedDescription)",
      )
      interactor.handleErrorWithTask(error)
      return []
    }
  }

  var body: some View {
    let items = _items
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
