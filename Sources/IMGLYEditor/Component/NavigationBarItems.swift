import IMGLYEngine
import SwiftUI

public extension NavigationBar {
  /// A namespace for navigation bar buttons.
  enum Buttons {}
}

public extension NavigationBar.Buttons {
  /// A namespace for navigation bar button IDs.
  enum ID {}
}

public extension NavigationBar.Buttons.ID {
  /// The id of the ``NavigationBar/Buttons/closeEditor(action:label:isEnabled:isVisible:)`` button.
  static var closeEditor: EditorComponentID { "ly.img.component.navigationBar.button.closeEditor" }
  /// The id of the ``NavigationBar/Buttons/undo(action:label:isEnabled:isVisible:)`` button.
  static var undo: EditorComponentID { "ly.img.component.navigationBar.button.undo" }
  /// The id of the ``NavigationBar/Buttons/redo(action:label:isEnabled:isVisible:)`` button.
  static var redo: EditorComponentID { "ly.img.component.navigationBar.button.redo" }
  /// The id of the ``NavigationBar/Buttons/export(action:label:isEnabled:isVisible:)`` button.
  static var export: EditorComponentID { "ly.img.component.navigationBar.button.export" }
  /// The id of the ``NavigationBar/Buttons/togglePreviewMode(action:label:isEnabled:isVisible:)`` button.
  static var togglePreviewMode: EditorComponentID { "ly.img.component.navigationBar.button.togglePreviewMode" }
  /// The id of the ``NavigationBar/Buttons/togglePagesMode(action:label:isEnabled:isVisible:)`` button.
  static var togglePagesMode: EditorComponentID { "ly.img.component.navigationBar.button.togglePagesMode" }
  /// The id of the ``NavigationBar/Buttons/previousPage(action:label:isEnabled:isVisible:)`` button.
  static var previousPage: EditorComponentID { "ly.img.component.navigationBar.button.previousPage" }
  /// The id of the ``NavigationBar/Buttons/nextPage(action:label:isEnabled:isVisible:)`` button.
  static var nextPage: EditorComponentID { "ly.img.component.navigationBar.button.nextPage" }
}

@MainActor
public extension NavigationBar.Buttons {
  /// Creates a ``NavigationBar/Button`` that closes the editor.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/closeEditor`` event
  /// is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a ``NavigationLabel`` with
  /// title "Back" is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is always `true`.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` while the editor is being created or
  /// if the current view mode is ``EditorViewMode/edit`` and engine setting `"features/pageCarouselEnabled"` is `true`
  /// or the current page is the first page of the scene.
  /// - Returns: The created button.
  static func closeEditor(
    action: @escaping NavigationBar.Context.To<Void> = { $0.eventHandler.send(.closeEditor) },
    @ViewBuilder label: @escaping NavigationBar.Context.To<some View> = { _ in
      NavigationLabel("Back", direction: .backward)
        .accessibilityLabel("Close Editor")
    },
    isEnabled: @escaping NavigationBar.Context.To<Bool> = { _ in true },
    isVisible: @escaping NavigationBar.Context.To<Bool> = {
      if !$0.state.isCreating, let engine = $0.engine {
        try $0.state.viewMode == .edit && (
          engine.editor.getSettingBool("features/pageCarouselEnabled") ||
            engine.scene.getPages().first == engine.scene.getCurrentPage()
        )
      } else {
        true
      }
    }
  ) -> some NavigationBar.Item {
    NavigationBar.Button(id: ID.closeEditor, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``NavigationBar/Button`` that performs an undo action.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, engine `EditorAPI.undo()` is
  /// invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a `Label` with title "Undo",
  /// icon ``IMGLY/undo``, and style ``IMGLY/adaptiveIconOnly`` is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is only `true` if the editor is created, the current
  /// view mode is not ``EditorViewMode/preview``, and engine `EditorAPI.canUndo()` is `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func undo(
    action: @escaping NavigationBar.Context.To<Void> = { try $0.engine?.editor.undo() },
    @ViewBuilder label: @escaping NavigationBar.Context.To<some View> = {
      Label { Text("Undo") } icon: { Image.imgly.undo }
        .opacity($0.state.viewMode == .preview ? 0 : 1)
        .labelStyle(.imgly.adaptiveIconOnly)
    },
    isEnabled: @escaping NavigationBar.Context.To<Bool> = {
      try !$0.state.isCreating && $0.state.viewMode != .preview && $0.engine?.editor.canUndo() == true
    },
    isVisible: @escaping NavigationBar.Context.To<Bool> = { _ in true }
  ) -> some NavigationBar.Item {
    NavigationBar.Button(id: ID.undo, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``NavigationBar/Button`` that performs a redo action.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, engine `EditorAPI.redo()` is
  /// invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a `Label` with title "Redo",
  /// icon ``IMGLY/redo``, and style ``IMGLY/adaptiveIconOnly`` is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is only `true` if the editor is created, the current
  /// view mode is not ``EditorViewMode/preview``, and engine `EditorAPI.canRedo()` is `true`.
  ///   - isVisible: Whether the button is visible. By default, it is always `true`.
  /// - Returns: The created button.
  static func redo(
    action: @escaping NavigationBar.Context.To<Void> = { try $0.engine?.editor.redo() },
    @ViewBuilder label: @escaping NavigationBar.Context.To<some View> = {
      Label { Text("Redo") } icon: { Image.imgly.redo }
        .opacity($0.state.viewMode == .preview ? 0 : 1)
        .labelStyle(.imgly.adaptiveIconOnly)
    },
    isEnabled: @escaping NavigationBar.Context.To<Bool> = {
      try !$0.state.isCreating && $0.state.viewMode != .preview && $0.engine?.editor.canRedo() == true
    },
    isVisible: @escaping NavigationBar.Context.To<Bool> = { _ in true }
  ) -> some NavigationBar.Item {
    NavigationBar.Button(id: ID.redo, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``NavigationBar/Button`` that performs an export action.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/startExport`` event
  /// is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a `Label` with title "Export",
  /// icon ``IMGLY/export``, and style ``IMGLY/adaptiveIconOnly`` is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is only `true` if the editor is created, is not
  /// exporting, and scene mode is `SceneMode.design` or the scene has a duration greater than 0.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` while the editor is being created or
  /// if the current view mode is not ``EditorViewMode/edit`` or engine setting `"features/pageCarouselEnabled"` is
  /// `true` or the current page is the last page of the scene.
  /// - Returns: The created button.
  static func export(
    action: @escaping NavigationBar.Context.To<Void> = { $0.eventHandler.send(.startExport) },
    @ViewBuilder label: @escaping NavigationBar.Context.To<some View> = { _ in
      Label { Text("Export") } icon: { Image.imgly.export }
        .labelStyle(.imgly.adaptiveIconOnly)
    },
    isEnabled: @escaping NavigationBar.Context.To<Bool> = {
      if !$0.state.isCreating, !$0.state.isExporting, let engine = $0.engine, let scene = try engine.scene.get() {
        try engine.scene.getMode() == .design || engine.block.getDuration(scene) > 0
      } else {
        false
      }
    },
    isVisible: @escaping NavigationBar.Context.To<Bool> = {
      if !$0.state.isCreating, let engine = $0.engine {
        try $0.state.viewMode != .edit || (
          engine.editor.getSettingBool("features/pageCarouselEnabled") ||
            engine.scene.getPages().last == engine.scene.getCurrentPage()
        )
      } else {
        true
      }
    }
  ) -> some NavigationBar.Item {
    NavigationBar.Button(id: ID.export, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``NavigationBar/Button`` that toggles between preview and edit mode.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/setViewMode(_:)``
  /// event is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a `Label` with title "Preview"
  /// or "Edit", icon ``IMGLY/preview``, and style ``IMGLY/adaptiveIconOnly`` is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is only `true` if the editor is created.
  ///   - isVisible: Whether the button is visible.  By default, it is always `true`.
  /// - Returns: The created button.
  static func togglePreviewMode(
    action: @escaping NavigationBar.Context.To<Void> = {
      $0.eventHandler.send(.setViewMode($0.state.viewMode == .preview ? .edit : .preview))
    },
    @ViewBuilder label: @escaping NavigationBar.Context.To<some View> = {
      let isPreviewMode = $0.state.viewMode == .preview
      return ZStack(alignment: .leading) {
        Label { Text("Preview") } icon: { Image.imgly.preview }
          .opacity(isPreviewMode ? 0 : 1)
        Label { Text("Edit") } icon: { Image.imgly.preview.symbolVariant(.fill) }
          .opacity(isPreviewMode ? 1 : 0)
      }
      .labelStyle(.imgly.adaptiveIconOnly)
      .accessibilityElement(children: .ignore) // Required for iOS 16 otherwise a11y label is exposed as "Edit, Edit".
      .accessibilityLabel(isPreviewMode ? "Edit" : "Preview")
    },
    isEnabled: @escaping NavigationBar.Context.To<Bool> = { !$0.state.isCreating },
    isVisible: @escaping NavigationBar.Context.To<Bool> = { _ in true }
  ) -> some NavigationBar.Item {
    NavigationBar.Button(
      id: ID.togglePreviewMode,
      action: action,
      label: label,
      isEnabled: isEnabled,
      isVisible: isVisible
    )
  }

  /// Creates a ``NavigationBar/Button`` that toggles between pages and edit mode.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default, ``EditorEvent/setViewMode(_:)``
  /// event is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a `Label` with title "Pages",
  /// icon ``IMGLY/pages`` and page count, and style ``IMGLY/adaptiveIconOnly`` is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is only `true` if the editor is created.
  ///   - isVisible: Whether the button is visible.  By default, it is `true` if the scene contains a stack, `false`
  /// otherwise.
  /// - Returns: The created button.
  static func togglePagesMode(
    action: @escaping NavigationBar.Context.To<Void> = {
      $0.eventHandler.send(.setViewMode($0.state.viewMode == .pages ? .edit : .pages))
    },
    @ViewBuilder label: @escaping NavigationBar.Context.To<some View> = {
      let isPagesMode = $0.state.viewMode == .pages
      let pageCount = try $0.engine?.scene.get() != nil ? $0.engine?.scene.getPages().count ?? 0 : 0
      return Label {
        Text(pageCount > 1 ? "Pages" : "Page")
          .padding(.leading, -4)
      } icon: {
        HStack {
          Image.imgly.pages
            .symbolVariant(isPagesMode ? .fill : .none)
          Text("\(pageCount)")
            .monospacedDigit()
            .font(.subheadline.weight(.semibold))
        }
      }
      .labelStyle(.imgly.adaptiveIconOnly)
      .accessibilityLabel(isPagesMode ? "Hide Pages" : "Show Pages")
    },
    isEnabled: @escaping NavigationBar.Context.To<Bool> = { !$0.state.isCreating },
    isVisible: @escaping NavigationBar.Context.To<Bool> = {
      try $0.state.isCreating || $0.engine?.block.find(byType: .stack).first != nil
    }
  ) -> some NavigationBar.Item {
    NavigationBar.Button(
      id: ID.togglePagesMode,
      action: action,
      label: label,
      isEnabled: isEnabled,
      isVisible: isVisible
    )
  }

  /// Creates a ``NavigationBar/Button`` that navigates to the previous page.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/navigateToPreviousPage`` event is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a ``NavigationLabel`` with
  /// title "Previous" is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is only `true` if the editor is created.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` when the editor is created, the
  /// current view mode is ``EditorViewMode/edit``, and engine setting `"features/pageCarouselEnabled"` is `true` or the
  /// current page is not the first page of the scene.
  /// - Returns: The created button.
  static func previousPage(
    action: @escaping NavigationBar.Context.To<Void> = { $0.eventHandler.send(.navigateToPreviousPage) },
    @ViewBuilder label: @escaping NavigationBar.Context.To<some View> = { _ in
      NavigationLabel("Previous", direction: .backward)
    },
    isEnabled: @escaping NavigationBar.Context.To<Bool> = { !$0.state.isCreating },
    isVisible: @escaping NavigationBar.Context.To<Bool> = {
      if !$0.state.isCreating, let engine = $0.engine {
        try $0.state.viewMode == .edit && (
          engine.editor.getSettingBool("features/pageCarouselEnabled") ||
            engine.scene.getPages().first != engine.scene.getCurrentPage()
        )
      } else {
        false
      }
    }
  ) -> some NavigationBar.Item {
    NavigationBar.Button(id: ID.previousPage, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }

  /// Creates a ``NavigationBar/Button`` that navigates to the next page.
  /// - Parameters:
  ///   - action: The action to perform when the user triggers the button. By default,
  /// ``EditorEvent/navigateToNextPage`` event is invoked.
  ///   - label: A view that describes the purpose of the button’s `action`. By default, a ``NavigationLabel`` with
  /// title "Next" is used.
  ///   - isEnabled: Whether the button is enabled. By default, it is only `true` if the editor is created.
  ///   - isVisible: Whether the button is visible. By default, it is only `true` when the editor is created, the
  /// current view mode is ``EditorViewMode/edit``, and engine setting `"features/pageCarouselEnabled"` is `true` or the
  /// current page is not the last page of the scene.
  /// - Returns: The created button.
  static func nextPage(
    action: @escaping NavigationBar.Context.To<Void> = { $0.eventHandler.send(.navigateToNextPage) },
    @ViewBuilder label: @escaping NavigationBar.Context.To<some View> = { _ in
      NavigationLabel("Next", direction: .forward)
    },
    isEnabled: @escaping NavigationBar.Context.To<Bool> = { !$0.state.isCreating },
    isVisible: @escaping NavigationBar.Context.To<Bool> = {
      if !$0.state.isCreating, let engine = $0.engine {
        try $0.state.viewMode == .edit && (
          engine.editor.getSettingBool("features/pageCarouselEnabled") ||
            engine.scene.getPages().last != engine.scene.getCurrentPage()
        )
      } else {
        false
      }
    }
  ) -> some NavigationBar.Item {
    NavigationBar.Button(id: ID.nextPage, action: action, label: label, isEnabled: isEnabled, isVisible: isVisible)
  }
}
