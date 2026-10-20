import SwiftUI

struct NavigationBarView: ViewModifier {
  // Interactor is not used directly (except error alert) but keep it to receive all updates to refresh navigation bar
  // on various conditions.
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglyEditorEnvironment) private var editorEnvironment

  let items: NavigationBar.Context.To<[NavigationBar.ItemGroup]>
  let context: NavigationBar.Context

  private var _groups: [NavigationBar.ItemPlacement: [any NavigationBar.Item]] {
    do {
      let items = try items(context)
      var groups = Dictionary(grouping: items) { $0.placement }.mapValues { $0.flatMap(\.items) }

      for modifications in editorEnvironment.navigationBarModifications {
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
        String(localized: .imgly.localized(
          "ly_img_editor_error_navigation_bar_view_creation \(error.localizedDescription)",
        )),
      )
      interactor.handleErrorWithTask(error)
      return [:]
    }
  }

  func body(content: Content) -> some View {
    content.modifier(AdaptiveNavigationBar(groups: _groups, context: context))
  }
}

private struct HorizontalNavigationBar: ViewModifier {
  let groups: [NavigationBar.ItemPlacement: [any NavigationBar.Item]]
  let context: NavigationBar.Context

  func body(content: Content) -> some View {
    content.toolbar {
      groups.toolbarContent(context, placement: .principal)
      groups.toolbarContent(context, placement: .topBarLeading)
      groups.toolbarContent(context, placement: .topBarTrailing)
    }
  }
}

// The vertical toolbar APIs exist from the iOS 27.1 SDK on. Xcode 27.0 has the same compiler without them, so the gate
// is the SwiftUI module version. Drop the `#if` once the minimum Xcode ships that SDK, and the `#available` once the
// deployment target reaches iOS 27.1.
#if canImport(SwiftUI, _version: 8.0.85)
  private struct AdaptiveNavigationBar: ViewModifier {
    let groups: [NavigationBar.ItemPlacement: [any NavigationBar.Item]]
    let context: NavigationBar.Context

    func body(content: Content) -> some View {
      if #available(iOS 27.1, *) {
        content.modifier(VerticalEdgeAwareNavigationBar(groups: groups, context: context))
      } else {
        content.modifier(HorizontalNavigationBar(groups: groups, context: context))
      }
    }
  }

  /// Lets the system stack the items along the vertical edge where one exists, such as the closed iPhone Duo's
  /// status strip. Everywhere else the bar is the horizontal one.
  @available(iOS 27.1, *)
  private struct VerticalEdgeAwareNavigationBar: ViewModifier {
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let groups: [NavigationBar.ItemPlacement: [any NavigationBar.Item]]
    let context: NavigationBar.Context

    func body(content: Content) -> some View {
      content.toolbar {
        if toolbarVerticalEdge != nil {
          // A vertical bar has no principal slot, so its items follow the leading ones.
          verticalItems(.topBarLeading, in: .topBarLeading)
          verticalItems(.principal, in: .topBarTrailing)
          verticalItems(.topBarTrailing, in: .topBarTrailing)
        } else {
          groups.toolbarContent(context, placement: .principal)
          groups.toolbarContent(context, placement: .topBarLeading)
          groups.toolbarContent(context, placement: .topBarTrailing)
        }
      }
      // The open iPhone Duo is regular width. It keeps the top bar, as Safari does, so the page centers on the display.
      .toolbarVerticalBehavior(horizontalSizeClass == .regular ? .disabled : .automatic)
    }

    @ToolbarContentBuilder
    private func verticalItems(
      _ placement: NavigationBar.ItemPlacement,
      in toolbarPlacement: ToolbarItemPlacement,
    ) -> some ToolbarContent {
      if let items = groups[placement], !items.isEmpty {
        // One group per placement and no `HStack`, so the system draws the items and ignores a label's `.opacity`:
        // undo and redo stay as disabled icons in preview mode. A `ToolbarItem` per button keeps the enabled state it
        // had when the bar was built, so the buttons stay disabled after loading.
        ToolbarItemGroup(placement: toolbarPlacement) {
          ForEach(items, id: \.id) { item in
            AnyView(item.nonThrowingBody(context))
              .environment(\.imglyNavigationBarIsVertical, true)
          }
        }
        .axisBehavior(.verticalPreferred)
      }
    }
  }
#else
  private typealias AdaptiveNavigationBar = HorizontalNavigationBar
#endif

extension EnvironmentValues {
  /// Whether the navigation bar item is laid out along a vertical edge, where labels show icons only.
  @Entry var imglyNavigationBarIsVertical = false
}

@MainActor
private extension [NavigationBar.ItemPlacement: [any NavigationBar.Item]] {
  @ToolbarContentBuilder
  func toolbarContent(_ context: NavigationBar.Context, placement: NavigationBar.ItemPlacement) -> some ToolbarContent {
    if let items = self[placement], !items.isEmpty {
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
              .frame(width: 0)
          }
          ForEach(items, id: \.id) { item in
            AnyView(item.nonThrowingBody(context))
          }
          if fixLeading {
            Button {} label: { EmptyView() }
              // `.buttonStyle(.automatic)` should be the default. Other styles don't do the trick.
              .frame(width: 0)
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
