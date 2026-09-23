@_spi(Internal) import IMGLYCoreUI
import SwiftUI

/// Groups the playback controls as a bar to be used above the timeline.
struct PlayerBarView: View {
  /// The configured header, evaluated per render.
  let header: Timeline.Header
  /// Modifications applied to the header in order.
  let headerModifications: [Timeline.Modifications]
  /// The context header ``Timeline/Item``s receive, built by ``Timeline`` and shared with the body.
  let itemContext: Timeline.ItemContext?

  @EnvironmentObject private var editorInteractor: Interactor

  /// A header item paired with the id its `ForEach` renders it under.
  private typealias UniqueItem = (id: EditorComponentID, item: any Timeline.Item)

  /// The visible header items per placement, after modifications. Visibility is resolved here
  /// rather than while rendering, so an empty header can drop the whole player bar.
  /// - Returns: `nil` when the header could not be resolved at all, which is not the same as a
  /// header that resolved to nothing. Only the latter may drop the bar.
  private func groups(in context: Timeline.ItemContext?) -> [Timeline.ItemPlacement: [UniqueItem]]? {
    guard let context else { return nil }
    do {
      var groups = Dictionary(grouping: try header(context)) { $0.placement }.mapValues { $0.flatMap(\.items) }
      for modifications in headerModifications {
        let modifier = Timeline.Modifier()
        try modifications(context, modifier)
        try modifier.apply(to: &groups)
      }
      // Return items with unique IDs, per group: each placement is its own `ForEach`, so a
      // non-unique id only has to be distinct among the items rendered beside it.
      return try groups.mapValues { items in
        try context.visible(items).enumerated().map {
          let item = $1
          var id = item.id
          if !id.isUnique {
            id.uniqueID = $0
          }
          return (id: id, item: item)
        }
      }
    } catch {
      let id = "ly.img.component.timeline"
      editorInteractor.handleErrorWithTask(EditorError(
        String(localized: .imgly.localized(
          "ly_img_editor_error_editor_component_view_creation \(id) \(error.localizedDescription)",
        )),
      ))
      return nil
    }
  }

  private func render(_ items: [UniqueItem], in context: Timeline.ItemContext) -> some View {
    ForEach(items, id: \.id) { value in
      AnyView(value.item.nonThrowingBody(context))
    }
  }

  var body: some View {
    let context = itemContext
    let groups = groups(in: context)
    // A header that could not be resolved keeps the bar, so a transient nil engine or one thrown
    // item does not drop the playback controls mid-render.
    let isEmpty = groups?.allSatisfy(\.value.isEmpty) ?? false
    // Not `CenteredLeadingTrailing`, which centers its side views: `ItemPlacement.leading` and
    // `.trailing` promise an edge, so each side group aligns to one. A `Timeline/Spacer` inside a
    // group still expands it to fill the slot, which is what spreads items within one group.
    HStack {
      HStack {
        if let context {
          render(groups?[.leading] ?? [], in: context)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if let context {
        render(groups?[.center] ?? [], in: context)
      }

      HStack {
        if let context {
          render(groups?[.trailing] ?? [], in: context)
        }
      }
      .frame(maxWidth: .infinity, alignment: .trailing)
    }
    // So a ``Timeline/Button`` reads as a header control rather than a tinted system button. Every
    // built-in item sets its own button style, so this only reaches integrator-supplied items.
    .buttonStyle(.plain)
    .preference(key: TimelineHeaderHiddenKey.self, value: isEmpty)
  }
}

/// Reports that the configured header resolved to no visible items, so the timeline can drop the
/// player bar entirely instead of leaving an empty strip.
struct TimelineHeaderHiddenKey: PreferenceKey {
  static let defaultValue = false
  static func reduce(value: inout Bool, nextValue: () -> Bool) {
    value = value || nextValue()
  }
}
