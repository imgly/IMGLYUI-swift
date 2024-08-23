import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
@_spi(Internal) import IMGLYCore

// MARK: - Public interface

public extension IMGLY where Wrapped: View {
  /// Sets the callback that is invoked when the editor is created. This is the main initialization block of both the
  /// editor and engine. Normally, you should load or create a scene as well as prepare asset sources in this block.
  /// This callback does not have a default implementation, as default scenes are solution-specific, however
  /// `OnCreate.loadScene` contains the default logic for most solutions. By default, it loads a scene and adds
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

  /// Sets the color palette used for UI elements that contain predefined color options, e.g., for "Fill Color" or
  /// "Stroke Color".
  /// - Parameter colors: An array of named colors. It should contain seven elements. Six of them are always shown. The
  /// seventh is only shown when a color property does not support a disabled state.
  /// - Returns: A view that has the given color palette set.
  func colorPalette(_ colors: [NamedColor]?) -> some View {
    wrapped.environment(\.imglyColorPalette, colors ?? ColorPaletteKey.defaultValue)
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
  func canvasAction(anchor: UnitPoint = .top, topSafeAreaInset: CGFloat, bottomSafeAreaInset: CGFloat,
                    @ViewBuilder action: @escaping () -> some View) -> some View {
    wrapped.modifier(CanvasAction(
      anchor: anchor,
      topSafeAreaInset: topSafeAreaInset,
      bottomSafeAreaInset: bottomSafeAreaInset,
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
      controller.largestUndimmedDetentIdentifier = largestUndimmedDetent?.identifier
      controller.prefersScrollingExpandsWhenScrolledToEdge = false
      controller.prefersEdgeAttachedInCompactHeight = true
    }
  }

  func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
    wrapped.background(WillDisappearHandler(onWillDisappear: perform))
  }
}
