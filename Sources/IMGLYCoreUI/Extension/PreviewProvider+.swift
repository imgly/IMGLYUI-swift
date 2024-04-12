@_spi(Internal) import IMGLYCore
import SwiftUI

private enum PreviewServerRequestState<Value> {
  case loading
  case loaded(Value)
  case error(Swift.Error)
}

@_spi(Internal) public extension PreviewProvider {
  @ViewBuilder static
  func previewState<Value>(_ value: Value,
                           @ViewBuilder content: @escaping (_ binding: Binding<Value>) -> some View) -> some View {
    StatefulPreviewContainer(value) { binding in
      content(binding)
    }
  }

  /// Get resource URL for main bundle or for local SwiftUI preview data server as fallback.
  static func getResource(port: UInt16 = PreviewServerRequest.defaultPort,
                          _ path: String, withExtension ext: String?) -> URL {
    Bundle.main.url(forResource: path, withExtension: ext) ??
      PreviewServerRequest.resource.url(port: port, path: path).appendingPathExtension(ext ?? "")
  }

  /// Fetch secrets from local SwiftUI preview data server.
  static func getSecrets(port: UInt16 = PreviewServerRequest.defaultPort,
                         @ViewBuilder content: @escaping (_ secrets: Secrets) -> some View) -> some View {
    previewState(PreviewServerRequestState<Secrets>.loading) { state in
      let request = PreviewServerRequest.secrets.url(port: port)
      switch state.wrappedValue {
      case .loading:
        ProgressView()
          .task {
            do {
              let (data, _) = try await URLSession.shared.get(request)
              let secrets = try JSONDecoder().decode(Secrets.self, from: data)
              state.wrappedValue = .loaded(secrets)
            } catch {
              state.wrappedValue = .error(error)
            }
          }
      case let .loaded(secrets):
        content(secrets)
      case let .error(error):
        VStack(alignment: .leading, spacing: 8) {
          Image(systemName: "exclamationmark.triangle")
            .imageScale(.large)
          Text("Could not fetch secrets from local SwiftUI preview data server!")
          Group {
            Text("Request: `\(request)`")
            Text("Error: \(error.localizedDescription)")
          }
          .font(.footnote)
        }
        .padding()
      }
    }
  }
}

extension PreviewProvider {
  @ViewBuilder static var assetLibraryPreview: some View {
    previewState(true) { binding in
      Button("Show Asset Library") {
        binding.wrappedValue = true
      }
      .sheet(isPresented: binding) {
        PreviewAssetLibrary()
      }
    }
  }

  @ViewBuilder static var defaultAssetLibraryPreviews: some View {
    assetLibraryPreview
    assetLibraryPreview.imgly.nonDefaultPreviewSettings()
  }
}

private struct PreviewAssetLibrary: View {
  @StateObject var interactor = AssetLibraryInteractorMock()
  @State var hidePresentationDragIndicator: Bool = false

  var body: some View {
    DefaultAssetLibrary()
      .imgly.assetLibrary(sceneMode: interactor.sceneMode)
      .imgly.assetLibrary(interactor: interactor)
      .imgly.assetLibraryDismissButton {
        Button {} label: {
          Label("Dismiss", systemImage: "chevron.down.circle.fill")
            .symbolRenderingMode(.hierarchical)
            .foregroundColor(.secondary)
            .font(.title2)
        }
      }
      .onPreferenceChange(PresentationDragIndicatorHiddenKey.self) { newValue in
        hidePresentationDragIndicator = newValue
      }
      .presentationDragIndicator(hidePresentationDragIndicator ? .hidden : .automatic)
      .presentationDetents([.medium, .large], selection: .constant(.large))
  }
}

private struct StatefulPreviewContainer<Value, Content: View>: View {
  @State var value: Value
  let content: (Binding<Value>) -> Content

  var body: some View {
    content($value)
  }

  init(_ value: Value, content: @escaping (_ binding: Binding<Value>) -> Content) {
    _value = .init(wrappedValue: value)
    self.content = content
  }
}
