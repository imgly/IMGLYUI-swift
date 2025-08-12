import SwiftUI

struct CanvasMenuView: View {
  // Interactor is not used directly (except error alert) but keep it to receive all updates to refresh canvas menu on
  // various conditions.
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglyCanvasMenuModifications) private var modifications

  let items: CanvasMenu.Context.To<[any CanvasMenu.Item]>
  let context: CanvasMenu.Context

  private typealias UniqueItem = (id: EditorComponentID, item: any CanvasMenu.Item)

  private var _items: [UniqueItem] {
    guard context.engine.block.isValid(context.selection.block) else {
      return []
    }
    do {
      var items = try items(context)
      if let modifications {
        let modifier = CanvasMenu.Modifier()
        try modifications(context, modifier)
        try modifier.apply(to: &items)
      }

      // Filter by visibility and remove adjacent dividers
      var previousItem: (any CanvasMenu.Item)?
      items = try items
        .filter {
          try $0.isVisible(context)
        }
        .reduce(into: []) { items, item in
          defer {
            previousItem = item
          }
          if previousItem is CanvasMenu.Divider, item is CanvasMenu.Divider {
            return
          }
          items.append(item)
        }

      // Remove dangling leading and trailing dividers
      var itemsSlice = items[...]
      if itemsSlice.first is CanvasMenu.Divider {
        itemsSlice = itemsSlice.dropFirst()
      }
      if itemsSlice.last is CanvasMenu.Divider {
        itemsSlice = itemsSlice.dropLast()
      }
      items = Array(itemsSlice)

      // Return items with unique IDs
      return items
        .enumerated()
        .map {
          let item = $1
          var id = item.id
          if !id.isUnique {
            id.uniqueID = $0
          }
          return (id: id, item: item)
        }
    } catch {
      let error = EditorError(
        "Could not create View for Canvas Menu.\nReason:\n\(error.localizedDescription)",
      )
      interactor.handleErrorWithTask(error)
      return []
    }
  }

  @ScaledMetric private var height = 38
  private var halfHeight: CGFloat { height / 2 }
  private let paddingFromSelectionBoundingBox: CGFloat = 24

  var body: some View {
    HStack(spacing: 0) {
      let items = _items
      ForEach(items, id: \.id) { value in
        AnyView(value.item.nonThrowingBody(context))
      }
    }
    .frame(height: height)
    .labelStyle(.imgly.canvasMenu(.iconOnly))
    .background(
      RoundedRectangle(cornerRadius: 8).fill(.bar)
        .shadow(color: .black.opacity(0.2), radius: 10),
    )
    .offset(y: -halfHeight - paddingFromSelectionBoundingBox)
  }
}
