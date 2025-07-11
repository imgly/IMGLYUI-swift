import SwiftUI

struct OnCreateKey: EnvironmentKey {
  static let defaultValue: OnCreate.Callback? = nil
}

struct OnExportKey: EnvironmentKey {
  static let defaultValue: OnExport.Callback? = nil
}

struct OnUploadKey: EnvironmentKey {
  static let defaultValue: OnUpload.Callback? = nil
}

struct OnCloseKey: EnvironmentKey {
  static let defaultValue: OnClose.Callback? = nil
}

struct OnErrorKey: EnvironmentKey {
  static let defaultValue: OnError.Callback? = nil
}

@_spi(Internal) public extension EnvironmentValues {
  var imglyOnCreate: OnCreate.Callback? {
    get { self[OnCreateKey.self] }
    set { self[OnCreateKey.self] = newValue }
  }

  var imglyOnExport: OnExport.Callback? {
    get { self[OnExportKey.self] }
    set { self[OnExportKey.self] = newValue }
  }

  var imglyOnUpload: OnUpload.Callback? {
    get { self[OnUploadKey.self] }
    set { self[OnUploadKey.self] = newValue }
  }

  var imglyOnClose: OnClose.Callback? {
    get { self[OnCloseKey.self] }
    set { self[OnCloseKey.self] = newValue }
  }

  var imglyOnError: OnError.Callback? {
    get { self[OnErrorKey.self] }
    set { self[OnErrorKey.self] = newValue }
  }
}

struct ConfigureableEditor: ViewModifier {
  @Environment(\.imglyOnCreate) private var onCreate
  @Environment(\.imglyOnExport) private var onExport
  @Environment(\.imglyOnUpload) private var onUpload
  @Environment(\.imglyOnClose) private var onClose
  @Environment(\.imglyOnError) private var onError
  @Environment(\.dismiss) private var dismiss

  let settings: EngineSettings
  let behavior: InteractorBehavior

  func body(content: Content) -> some View {
    let callbacks = EngineCallbacks(
      onCreate: onCreate ?? OnCreate.default,
      onExport: onExport ?? OnExport.default,
      onUpload: onUpload ?? OnUpload.default,
      onClose: onClose ?? OnClose.default,
      onError: onError ?? OnError.default
    )
    let config = EngineConfiguration(settings: settings, callbacks: callbacks)
    content
      .modifier(InteractableEditor(config: config, behavior: behavior, dismiss: dismiss))
  }
}

private struct InteractableEditor: ViewModifier {
  @StateObject private var interactor: Interactor

  init(config: EngineConfiguration, behavior: InteractorBehavior, dismiss: DismissAction) {
    _interactor = .init(wrappedValue: .init(config: config, behavior: behavior, dismiss: dismiss))
  }

  func body(content: Content) -> some View {
    content
      .imgly.interactor(interactor)
  }
}
