import IMGLYEngine
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

// MARK: - Public interface

public extension IMGLY where Wrapped: View {
  // MARK: - Configuration

  /// Configures the editor using one or more composable configurations.
  ///
  /// This modifier replaces the entire editor configuration. If called multiple times, only the
  /// innermost call takes effect. Configurations within a single call are applied in order.
  ///
  /// - Parameter configurations: A result builder closure that returns an array of configurations.
  /// - Returns: A view with the configurations applied.
  @MainActor
  func configuration(
    @EditorConfigurationResultBuilder _ configurations: @escaping () -> [EditorConfiguration],
  ) -> some View {
    wrapped.transformEnvironment(\.imglyEditorEnvironment) { current in
      let configs = configurations()
      let builder = EditorConfigurationComposer()

      for config in configs {
        config.configure(builder)
      }

      current = builder.build()
    }
  }
}

// MARK: - Internal interface

@_spi(Internal) public extension IMGLY where Wrapped: View {
  func selection(_ id: DesignBlockID?) -> some View {
    wrapped.environment(\.imglySelection, id)
  }
}

extension IMGLY where Wrapped: View {
  func editor(_ settings: EngineSettings) -> some View {
    wrapped.modifier(ConfigurableEditor(settings: settings))
  }

  func fontFamilies(_ families: [String]?) -> some View {
    wrapped.environment(\.imglyFontFamilies, families ?? FontFamiliesKey.defaultValue)
  }

  func colorPalette(_ colors: [NamedColor]?) -> some View {
    wrapped.transformEnvironment(\.imglyEditorEnvironment) { env in
      env.colorPalette = colors ?? ColorPalette.defaultValue
    }
  }

  @MainActor
  func interactor(_ interactor: Interactor) -> some View {
    selection(interactor.selection?.blocks.first)
      .environmentObject(interactor)
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
      action: action,
    ))
  }

  @MainActor
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

  @MainActor
  func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
    wrapped.background(WillDisappearHandler(onWillDisappear: perform))
  }

  @MainActor
  func alert(_ presented: Binding<Bool>, @ViewBuilder content: @escaping () -> some View) -> some View {
    wrapped.modifier(AlertOverlay(isPresented: presented, overlay: content))
  }
}
