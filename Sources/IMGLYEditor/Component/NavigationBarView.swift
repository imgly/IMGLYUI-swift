import SwiftUI

struct NavigationBarView: ViewModifier {
  // Interactor is not used directly (except error alert) but keep it to receive all updates to refresh navigation bar
  // on various conditions.
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglyNavigationBarModifications) private var modifications

  let items: NavigationBar.Context.To<[NavigationBar.ItemGroup]>
  let context: NavigationBar.Context

  private var _groups: [NavigationBar.ItemPlacement: [any NavigationBar.Item]] {
    do {
      let items = try items(context)
      var groups = Dictionary(grouping: items) { $0.placement }.mapValues { $0.flatMap(\.items) }

      if let modifications {
        let modifier = NavigationBar.Modifier()
        try modifications(context, modifier)
        try modifier.apply(to: &groups)
      }
      return try groups.mapValues { items in
        try items.filter {
          try $0.isVisible(context)
        }
      }
    } catch {
      let error = EditorError(
        "Could not create View for Navigation Bar.\nReason:\n\(error.localizedDescription)",
      )
      interactor.handleErrorWithTask(error)
      return [:]
    }
  }

  func body(content: Content) -> some View {
    let groups = _groups

    content.toolbar {
      groups.toolbarContent(context, placement: .principal)
      groups.toolbarContent(context, placement: .topBarLeading)
      groups.toolbarContent(context, placement: .topBarTrailing)
    }
  }
}

@MainActor
private extension [NavigationBar.ItemPlacement: [any NavigationBar.Item]] {
  @ToolbarContentBuilder
  func toolbarContent(_ context: NavigationBar.Context, placement: NavigationBar.ItemPlacement) -> some ToolbarContent {
    if let items = self[placement] {
      ToolbarItemGroup(placement: placement.toolbarItemPlacement) {
        // 1) For `.principal` placement a HStack is required otherwise just the first item is displayed.
        // 2) HStack breaks automatic overflow menu (...) for `.topBarTrailing` placement but enables us to apply
        //    `.labelStyle`s, `.opacity`, and many more view modifiers.
        // 3) Without HStack hiding items like undo/redo in preview mode would only work with `.tint(.clear)`.
        // 4) Label style is not applied if there is "just" a single element for `.topBarTrailing`. Can be worked around
        //    by using `HStack { Image(...) Text(...) }` instead of `Label` or by making sure that there is always a
        //    second element.
        // 5) Postcard "write" button is not clickable on iOS 17+.
        let fixLeading = placement == .topBarLeading && items.count == 1 // Fix for 4)
        let fixTrailing = placement == .topBarTrailing && items.count == 1 // Fix for 4) and 5)
        HStack(spacing: fixLeading || fixTrailing ? 0 : 16) {
          if fixTrailing {
            Button {} label: { EmptyView() }
              // `.buttonStyle(.automatic)` should be the default. Other styles don't do the trick.
              .padding(.trailing, -7)
          }
          ForEach(items, id: \.id) { item in
            AnyView(item.nonThrowingBody(context))
          }
          if fixLeading {
            Button {} label: { EmptyView() }
              // `.buttonStyle(.automatic)` should be the default. Other styles don't do the trick.
              .padding(.leading, -7)
          }
        }
      }
    }
  }
}

private extension NavigationBar.ItemPlacement {
  var toolbarItemPlacement: ToolbarItemPlacement {
    switch self {
    case .principal: .principal
    case .topBarLeading: .topBarLeading
    case .topBarTrailing: .topBarTrailing
    }
  }
}
