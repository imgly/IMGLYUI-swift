import SwiftUI
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public extension EnvironmentValues {
  @Entry var imglyOnCreate: OnCreate.Callback?
  @Entry var imglyOnLoaded: OnLoaded.Callback?
  @Entry var imglyOnExport: OnExport.Callback?
  @Entry var imglyOnUpload: OnUpload.Callback?
  @Entry var imglyOnClose: OnClose.Callback?
  @Entry var imglyOnError: OnError.Callback?
  @Entry var imglyOnChanged: OnChanged.Callback?
}

struct ConfigureableEditor: ViewModifier {
  @Environment(\.imglyOnCreate) private var onCreate
  @Environment(\.imglyOnLoaded) private var onLoaded
  @Environment(\.imglyOnExport) private var onExport
  @Environment(\.imglyOnUpload) private var onUpload
  @Environment(\.imglyOnClose) private var onClose
  @Environment(\.imglyOnError) private var onError
  @Environment(\.imglyOnChanged) private var onChanged
  @Environment(\.dismiss) private var dismiss

  @Environment(\.imglyAssetLibrary) private var anyAssetLibrary

  private var assetLibrary: some AssetLibrary {
    anyAssetLibrary ?? AnyAssetLibrary(erasing: DefaultAssetLibrary())
  }

  let settings: EngineSettings
  let behavior: InteractorBehavior

  func body(content: Content) -> some View {
    let callbacks = EngineCallbacks(
      onCreate: onCreate ?? OnCreate.default,
      onLoaded: onLoaded ?? OnLoaded.default,
      onExport: onExport ?? OnExport.default,
      onUpload: onUpload ?? OnUpload.default,
      onClose: onClose ?? OnClose.default,
      onError: onError ?? OnError.default,
      onChanged: onChanged ?? OnChanged.default,
    )
    let config = EngineConfiguration(settings: settings, callbacks: callbacks)
    content
      .modifier(InteractableEditor(
        config: config,
        behavior: behavior,
        dismiss: dismiss,
        assetLibrary: assetLibrary,
      ))
  }
}

private struct InteractableEditor: ViewModifier {
  @StateObject private var interactor: Interactor

  init(
    config: EngineConfiguration,
    behavior: InteractorBehavior,
    dismiss: DismissAction,
    assetLibrary: any AssetLibrary,
  ) {
    _interactor = .init(wrappedValue: .init(
      config: config,
      behavior: behavior,
      dismiss: dismiss,
      assetLibrary: assetLibrary,
    ))
  }

  func body(content: Content) -> some View {
    content
      .imgly.interactor(interactor)
  }
}
