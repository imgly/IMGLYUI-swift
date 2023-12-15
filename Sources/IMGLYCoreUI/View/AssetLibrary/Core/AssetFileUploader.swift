@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI
import UniformTypeIdentifiers

struct AssetFileUploader: ViewModifier {
  @Environment(\.imglyAssetLibrarySources) private var sources
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor

  @Binding var isPresented: Bool
  let allowedContentTypes: [UTType]
  typealias Completion = (Result<AssetResult, Swift.Error>) -> Void
  let onCompletion: Completion

  func body(content: Content) -> some View {
    content
      .fileImporter(isPresented: $isPresented, allowedContentTypes: allowedContentTypes) { result in
        guard let source = sources.first else {
          return
        }
        Task {
          do {
            let asset = try await interactor.uploadAsset(to: source.id) {
              let securityScopedURL = try result.get()
              guard securityScopedURL.startAccessingSecurityScopedResource() else {
                throw Error(errorDescription: "Could not access security scoped resource.")
              }
              defer { securityScopedURL.stopAccessingSecurityScopedResource() }
              let url = try FileManager.default.getUniqueCacheURL()
                .appendingPathExtension(securityScopedURL.pathExtension)
              try FileManager.default.copyItem(at: securityScopedURL, to: url)

              let contentType: UTType
              do {
                contentType = try url.contentType()
              } catch {
                guard allowedContentTypes.count == 1,
                      let allowedContentType = allowedContentTypes.first else {
                  throw Error(errorDescription: "Could not determine content type.")
                }
                contentType = allowedContentType
              }

              return try .init(
                url: url,
                blockType: contentType.blockType(),
                blockKind: contentType.blockKind(),
                fillType: contentType.fillType()
              )
            }
            onCompletion(.success(asset))
          } catch {
            onCompletion(.failure(error))
          }
        }
      }
  }
}

private extension URL {
  func contentType() throws -> UTType {
    guard let contentType = try resourceValues(forKeys: [.contentTypeKey]).contentType else {
      throw Error(errorDescription: "Could not access content type resource value.")
    }
    return contentType
  }
}

private extension UTType {
  func blockType() throws -> DesignBlockType {
    if conforms(to: .video) || conforms(to: .image) {
      return .graphic
    } else if conforms(to: .audio) {
      return .audio
    }
    throw Error(errorDescription: "Unsupported content type to block type mapping.")
  }

  func blockKind() throws -> BlockKind {
    if conforms(to: .video) {
      return .key(.video)
    } else if conforms(to: .audio) {
      return .key(.audio)
    } else if conforms(to: .image) {
      return .key(.image)
    }
    throw Error(errorDescription: "Unsupported content type to block kind mapping.")
  }

  func fillType() -> FillType? {
    if conforms(to: .video) {
      return .video
    } else if conforms(to: .image) {
      return .image
    }
    return nil
  }
}

struct AssetFileUploader_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
