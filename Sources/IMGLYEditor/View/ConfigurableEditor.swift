import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct ConfigurableEditor: ViewModifier {
  @Environment(\.imglyEditorEnvironment) private var editorEnvironment
  @Environment(\.dismiss) private var dismiss

  private var assetLibrary: some AssetLibrary {
    let categories = AssetLibraryCategory.defaultCategories
    return AnyAssetLibrary(erasing: editorEnvironment.makeAssetLibrary(defaultCategories: categories))
  }

  let settings: EngineSettings

  func body(content: Content) -> some View {
    let callbacks = EngineCallbacks(
      onCreate: editorEnvironment.onCreate ?? OnCreate.default,
      onLoaded: editorEnvironment.onLoaded ?? OnLoaded.default,
      onExport: editorEnvironment.onExport ?? { _, _ in print("OnExport not implemented.") },
      onUpload: editorEnvironment.onUpload ?? OnUpload.default,
      onClose: editorEnvironment.onClose ?? OnClose.default,
      onError: editorEnvironment.onError ?? OnError.default,
      onChanged: editorEnvironment.onChanged ?? OnChanged.default,
    )
    let config = EngineConfiguration(settings: settings, callbacks: callbacks)
    content
      .modifier(InteractableEditor(config: config, dismiss: dismiss, assetLibrary: assetLibrary))
  }
}

private struct InteractableEditor: ViewModifier {
  @StateObject private var interactor: Interactor

  init(
    config: EngineConfiguration,
    dismiss: DismissAction,
    assetLibrary: any AssetLibrary,
  ) {
    _interactor = .init(wrappedValue: .init(
      config: config,
      dismiss: dismiss,
      assetLibrary: assetLibrary,
    ))
  }

  func body(content: Content) -> some View {
    content
      .imgly.interactor(interactor)
  }
}
