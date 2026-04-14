import SwiftUI

struct InspectorBarView: View {
  // Interactor is not used directly (except error alert) but keep it to receive all updates to refresh inspector bar on
  // various conditions.
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglyInspectorBarModifications) private var modifications

  let items: InspectorBar.Context.To<[any InspectorBar.Item]>
  let context: InspectorBar.Context

  private var _items: [any InspectorBar.Item] {
    guard context.engine.block.isValid(context.selection.block) else {
      return []
    }
    do {
      var items = try items(context)
      if let modifications {
        let modifier = InspectorBar.Modifier()
        try modifications(context, modifier)
        try modifier.apply(to: &items)
      }
      return try items.filter {
        try $0.isVisible(context)
      }
    } catch {
      let error = EditorError(
        "Could not create View for Inspector Bar.\nReason:\n\(error.localizedDescription)",
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
  }
}
