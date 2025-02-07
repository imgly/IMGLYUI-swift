import SwiftUI

struct InspectorBarView: View {
  // Interactor is not used directly (except error alert) but keep it to receive all updates to refresh dock on various
  // conditions.
  @EnvironmentObject private var interactor: Interactor

  let inspectorBar: InspectorBar.Context.To<[any InspectorBar.Item]>
  let context: InspectorBar.Context

  var items: [any InspectorBar.Item] {
    guard context.engine.block.isValid(context.selection.id) else {
      return []
    }
    do {
      return try inspectorBar(context).filter {
        try $0.isVisible(context)
      }
    } catch {
      let error = EditorError(
        "Could not create View for Inspector Bar.\nReason:\n\(error.localizedDescription)"
      )
      interactor.handleErrorWithTask(error)
      return []
    }
  }

  var body: some View {
    let items = items
    ForEach(items, id: \.id) { item in
      AnyView(item.nonThrowingBody(context))
    }
  }
}
