import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
@_spi(Internal) import IMGLYCore

// MARK: - Public interface

public extension IMGLY where Wrapped: View {
  func onCreate(_ onCreate: @escaping OnCreate.Callback) -> some View {
    wrapped.environment(\.imglyOnCreate, onCreate)
  }

  func onExport(_ onExport: @escaping OnExport.Callback) -> some View {
    wrapped.environment(\.imglyOnExport, onExport)
  }

  func onUpload(_ onUpload: @escaping OnUpload.Callback) -> some View {
    wrapped.environment(\.imglyOnUpload, onUpload)
  }

  func colorPalette(_ colors: [NamedColor]?) -> some View {
    wrapped.environment(\.imglyColorPalette, colors ?? ColorPaletteKey.defaultValue)
  }

  func fontFamilies(_ families: [String]?) -> some View {
    wrapped.environment(\.imglyFontFamilies, families ?? FontFamiliesKey.defaultValue)
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
  @MainActor
  func interactor(_ interactor: Interactor) -> some View {
    selection(interactor.selection?.blocks.first)
      .environmentObject(interactor)
  }

  func selection(_ id: Interactor.BlockID?) -> some View {
    wrapped.environment(\.imglySelection, id)
  }

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
          return .enabled(upThrough: largestUndimmedDetent)
        } else {
          return .disabled
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
