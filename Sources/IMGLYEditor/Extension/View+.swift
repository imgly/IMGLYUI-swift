import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

// MARK: - Public interface

public extension IMGLY where Wrapped: View {
  /// Sets the callback that is invoked when the editor is created. This is the main initialization block of both the
  /// editor and engine. Normally, you should load or create a scene as well as prepare asset sources in this block.
  /// This callback does not have a default implementation, as default scenes are solution-specific, however
  /// ``OnCreate/loadScene(from:)`` contains the default logic for most solutions. By default, it loads a scene and adds
  /// all default and demo asset sources.
  /// - Parameter onCreate: The callback.
  /// - Returns: A view that has the given callback set.
  func onCreate(_ onCreate: @escaping OnCreate.Callback) -> some View {
    wrapped.environment(\.imglyOnCreate, onCreate)
  }

  /// Sets the callback that is invoked when the export button is tapped. You may want to call one of the engine's
  /// export functions in this callback. The default implementations call `BlockAPI.export` or `BlockAPI.exportVideo`
  /// based on the engine's `SceneMode`, display a progress indicator for video exports, write the content into a
  /// temporary file, and open a system dialog for sharing the exported file.
  /// - Parameter onExport: The callback.
  /// - Returns: A view that has the given callback set.
  func onExport(_ onExport: @escaping OnExport.Callback) -> some View {
    wrapped.environment(\.imglyOnExport, onExport)
  }

  /// Sets the callback that is invoked after an asset is added to an asset source. When selecting an asset to upload, a
  /// default `AssetDefinition` object is constructed based on the selected asset and the callback is invoked. By
  /// default, the callback leaves the asset definition unmodified and returns the same object. However, you may want to
  /// upload the selected asset to your server before adding it to the scene.
  /// - Parameter onUpload: The callback.
  /// - Returns: A view that has the given callback set.
  func onUpload(_ onUpload: @escaping OnUpload.Callback) -> some View {
    wrapped.environment(\.imglyOnUpload, onUpload)
  }

  /// Sets the asset library UI definition used by the editor. By default, the predefined ``DefaultAssetLibrary`` is
  /// used. To use custom asset sources in the asset library UI, the custom asset source must be first added to the
  /// engine. In addition to creating or loading a scene, registering the asset sources should be done in the
  /// ``onCreate(_:)`` callback.
  /// - Parameter assetLibrary: The asset library.
  /// - Returns: A view that has the given asset library set.
  @MainActor
  func assetLibrary(_ assetLibrary: () -> some AssetLibrary) -> some View {
    wrapped.environment(\.imglyAssetLibrary, AnyAssetLibrary(erasing: assetLibrary()))
  }

  /// Sets the color palette used for UI elements that contain predefined color options, e.g., for "Fill Color" or
  /// "Stroke Color".
  /// - Parameter colors: An array of named colors. It should contain seven elements. Six of them are always shown. The
  /// seventh is only shown when a color property does not support a disabled state.
  /// - Returns: A view that has the given color palette set.
  func colorPalette(_ colors: [NamedColor]?) -> some View {
    wrapped.environment(\.imglyColorPalette, colors ?? ColorPaletteKey.defaultValue)
  }

  /// Sets the registered ``Dock/Item``s and defines their order for the ``Dock`` UI component of the editor. The
  /// default implementation of this modifier depends on the used editor solution.
  /// - Note: Registering does not mean displaying. The `items` will be displayed if
  /// ``EditorComponent/isVisible(_:)-hdb5`` returns `true` for them.
  ///
  /// The default implementations of this modifier are:
  /// ```swift
  ///  DesignEditor(settings)
  ///    .imgly.dockItems { context in
  ///      Dock.Buttons.elementsLibrary()
  ///      Dock.Buttons.photoRoll()
  ///      Dock.Buttons.systemCamera()
  ///      Dock.Buttons.imagesLibrary()
  ///      Dock.Buttons.textLibrary()
  ///      Dock.Buttons.shapesLibrary()
  ///      Dock.Buttons.stickersLibrary()
  ///    }
  ///
  ///  PhotoEditor(settings)
  ///    .imgly.dockItems { context in
  ///      Dock.Buttons.adjustments()
  ///      Dock.Buttons.filter()
  ///      Dock.Buttons.effect()
  ///      Dock.Buttons.blur()
  ///      Dock.Buttons.crop()
  ///      Dock.Buttons.textLibrary()
  ///      Dock.Buttons.shapesLibrary()
  ///      Dock.Buttons.stickersLibrary()
  ///    }
  ///
  ///  VideoEditor(settings)
  ///    .imgly.dockItems { context in
  ///      Dock.Buttons.photoRoll()
  ///      Dock.Buttons.imglyCamera()
  ///      Dock.Buttons.overlaysLibrary()
  ///      Dock.Buttons.textLibrary()
  ///      Dock.Buttons.stickersAndShapesLibrary()
  ///      Dock.Buttons.audioLibrary()
  ///      Dock.Buttons.voiceover()
  ///      Dock.Buttons.reorder()
  ///    }
  /// ```
  /// - Parameter items: A ``Dock/Builder`` closure that provides the ``Dock/Context`` and returns an array of
  /// ``Dock/Item``s.
  /// - Returns: A view that has the given items set.
  func dockItems(@Dock.Builder _ items: @escaping Dock.Items) -> some View {
    wrapped.environment(\.imglyDockItems, items)
  }

  /// Sets the modifications that should be applied to the order of ``Dock/Items``s defined by ``dockItems(_:)``.
  /// This modifier can be used, when you do not want to touch the default general order of the items, but rather add
  /// additional items and replace/hide some of the default items. By default, no modifications are applied.
  /// - Warning: Note that the order of items may change between editor versions, therefore
  /// ``modifyDockItems(_:)`` must be used with care. Consider overwriting the default items instead with
  /// ``dockItems(_:)`` if you want to have strict ordering between different editor versions.
  /// - Parameter modifications: A closure that provides the ``Dock/Context`` as first and a ``Dock/Modifier`` as second
  /// argument. Use the modifier to change the items.
  /// - Returns: A view that has the given modifications set.
  func modifyDockItems(_ modifications: @escaping Dock.Modifications) -> some View {
    wrapped.environment(\.imglyDockModifications, modifications)
  }

  /// Sets the registered ``InspectorBar/Item``s and defines their order for the ``InspectorBar`` UI component of the
  /// editor. By default, the same items are used for all editor solutions.
  /// - Note: Registering does not mean displaying. The `items` will be displayed if
  /// ``EditorComponent/isVisible(_:)-hdb5`` returns `true` for them.
  ///
  /// The default implementation of this modifier is:
  /// ```swift
  /// .imgly.inspectorBarItems { context in
  ///   InspectorBar.Buttons.replace() // Video, Image, Sticker, Audio
  ///   InspectorBar.Buttons.editText() // Text
  ///   InspectorBar.Buttons.formatText() // Text
  ///   InspectorBar.Buttons.fillStroke() // Page, Video, Image, Shape, Text
  ///   InspectorBar.Buttons.editVoiceover() // Voiceover
  ///   InspectorBar.Buttons.volume() // Video, Audio, Voiceover
  ///   InspectorBar.Buttons.crop() // Video, Image
  ///   InspectorBar.Buttons.adjustments() // Video, Image
  ///   InspectorBar.Buttons.filter() // Video, Image
  ///   InspectorBar.Buttons.effect() // Video, Image
  ///   InspectorBar.Buttons.blur() // Video, Image
  ///   InspectorBar.Buttons.shape() // Video, Image, Shape
  ///   InspectorBar.Buttons.selectGroup() // Video, Image, Sticker, Shape, Text
  ///   InspectorBar.Buttons.enterGroup() // Group
  ///   InspectorBar.Buttons.layer() // Video, Image, Sticker, Shape, Text
  ///   InspectorBar.Buttons.split() // Video, Image, Sticker, Shape, Text, Audio
  ///   InspectorBar.Buttons.moveAsClip() // Video, Image, Sticker, Shape, Text
  ///   InspectorBar.Buttons.moveAsOverlay() // Video, Image, Sticker, Shape, Text
  ///   InspectorBar.Buttons.reorder() // Video, Image, Sticker, Shape, Text
  ///   InspectorBar.Buttons.duplicate() // Video, Image, Sticker, Shape, Text, Audio
  ///   InspectorBar.Buttons.delete() // Video, Image, Sticker, Shape, Text, Audio, Voiceover
  /// }
  /// ```
  /// - Parameter items: A ``InspectorBar/Builder`` closure that provides the ``InspectorBar/Context`` and returns an
  /// array of ``InspectorBar/Item``s.
  /// - Returns: A view that has the given items set.
  func inspectorBarItems(@InspectorBar.Builder _ items: @escaping InspectorBar.Items) -> some View {
    wrapped.environment(\.imglyInspectorBarItems, items)
  }

  /// Sets the modifications that should be applied to the order of ``InspectorBar/Items``s defined by
  /// ``inspectorBarItems(_:)``. This modifier can be used, when you do not want to touch the default general
  /// order of the items, but rather add additional items and replace/hide some of the default items. By default, no
  /// modifications are applied.
  /// - Warning: Note that the order of items may change between editor versions, therefore
  /// ``modifyInspectorBarItems(_:)`` must be used with care. Consider overwriting the default items instead with
  /// ``inspectorBarItems(_:)`` if you want to have strict ordering between different editor versions.
  /// - Parameter modifications: A closure that provides the ``InspectorBar/Context`` as first and a
  /// ``InspectorBar/Modifier`` as second argument. Use the modifier to change the items.
  /// - Returns: A view that has the given modifications set.
  func modifyInspectorBarItems(_ modifications: @escaping InspectorBar.Modifications) -> some View {
    wrapped.environment(\.imglyInspectorBarModifications, modifications)
  }
}

// MARK: - Internal interface

@_spi(Internal) public extension IMGLY where Wrapped: View {
  func editor(_ settings: EngineSettings, behavior: InteractorBehavior) -> some View {
    wrapped.modifier(ConfigureableEditor(settings: settings, behavior: behavior))
  }

  func pageNavigation(_ enabled: Bool) -> some View {
    wrapped.environment(\.imglyIsPageNavigationEnabled, enabled)
  }
}

extension IMGLY where Wrapped: View {
  func fontFamilies(_ families: [String]?) -> some View {
    wrapped.environment(\.imglyFontFamilies, families ?? FontFamiliesKey.defaultValue)
  }

  @MainActor
  func interactor(_ interactor: Interactor) -> some View {
    selection(interactor.selection?.blocks.first)
      .environmentObject(interactor)
  }

  func selection(_ id: Interactor.BlockID?) -> some View {
    wrapped.environment(\.imglySelection, id)
  }

  @MainActor
  func canvasAction(anchor: UnitPoint = .top,
                    topSafeAreaInset: CGFloat,
                    bottomSafeAreaInset: CGFloat,
                    isVisible: Bool = true,
                    @ViewBuilder action: @escaping () -> some View) -> some View {
    wrapped.modifier(CanvasAction(
      anchor: anchor,
      topSafeAreaInset: topSafeAreaInset,
      bottomSafeAreaInset: bottomSafeAreaInset,
      isVisible: isVisible,
      action: action
    ))
  }

  func errorAlert(isSheet: Bool) -> some View {
    wrapped.modifier(ErrorAlert(isSheet: isSheet))
  }

  @MainActor @ViewBuilder
  func presentationConfiguration(_ largestUndimmedDetent: PresentationDetent?) -> some View {
    if #available(iOS 16.4, *) {
      wrapped.presentationBackgroundInteraction({
        if let largestUndimmedDetent {
          .enabled(upThrough: largestUndimmedDetent)
        } else {
          .disabled
        }
      }())
        .presentationContentInteraction(.scrolls)
        .presentationCompactAdaptation(.sheet)
    } else {
      legacyPresentationConfiguration(largestUndimmedDetent)
    }
  }

  @MainActor @ViewBuilder
  private func legacyPresentationConfiguration(_ largestUndimmedDetent: PresentationDetent?) -> some View {
    wrapped.introspect(.viewController, on: .iOS(.v16...), scope: .ancestor) { viewController in
      guard let controller = viewController.sheetPresentationController else {
        return
      }
      controller.presentingViewController.view?.tintAdjustmentMode = .normal
      controller.largestUndimmedDetentIdentifier = largestUndimmedDetent?.imgly.identifier
      controller.prefersScrollingExpandsWhenScrolledToEdge = false
      controller.prefersEdgeAttachedInCompactHeight = true
    }
  }

  func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
    wrapped.background(WillDisappearHandler(onWillDisappear: perform))
  }
}
