@_spi(Internal) import IMGLYCore
import SwiftUI

/// A grid view that displays photo roll assets from the user's photo library with an add button as the first item
/// to allow importing additional media.
public struct PhotoRollDestination: View {
  @Environment(\.imglyAssetLibrarySources) private var sources
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  @EnvironmentObject private var configuration: AssetLibrarySectionConfiguration
  private let media: [PhotoRollMediaType]

  @Feature(.photosPickerMultiSelect) private var isPhotosPickerMultiSelectEnabled: Bool

  private var mediaCompletion: MediaCompletion {
    { result in
      guard let source = sources.first else {
        return
      }
      Task {
        for (url, media) in try result.get() {
          _ = try await interactor.uploadAsset(to: source.id) {
            switch media {
            case .image: .init(url: url, blockType: .graphic, blockKind: .key(.image), fillType: .image)
            case .movie: .init(url: url, blockType: .graphic, blockKind: .key(.video), fillType: .video)
            }
          }
        }
      }
    }
  }

  private var maxSelectionCount: Int? {
    isPhotosPickerMultiSelectEnabled ? nil : 1
  }

  @State private var showImagePicker = false

  /// Creates a grid view of photo roll assets with add functionality.
  /// - Parameter media: The allowed media type(s).
  public init(media: [PhotoRollMediaType]) {
    self.media = media
  }

  private var emptyView: some View {
    VStack(spacing: 30) {
      if interactor.isPhotoRollFullLibraryAccessEnabled {
        if PhotoLibraryAuthorizationManager.shared.isAuthorized {
          Message.noElements

          PhotoRollAddMenu(media: media) {
            makeEmptyStateButton {} label: {
              AddLabel()
            }
          }
        } else {
          Button {
            AppSettingsHelper.openAppSettings()
          } label: {
            Message(.imgly.localized("ly_img_editor_asset_library_label_grant_permissions"))
          }

          makeEmptyStateButton {
            AppSettingsHelper.openAppSettings()
          } label: {
            Text(.imgly.localized("ly_img_editor_asset_library_button_permissions"))
          }
        }
      } else {
        UploadGridAddButton(showUploader: $showImagePicker)
      }
    }
  }

  private var firstAddButton: some View {
    Group {
      if interactor.isPhotoRollFullLibraryAccessEnabled {
        PhotoRollAddMenu(media: media) {
          ZStack {
            GridItemBackground()
            VStack(spacing: 6) {
              Image(systemName: "plus")
                .imageScale(.large)
              Text(.imgly.localized("ly_img_editor_asset_library_button_add"))
                .font(.caption.weight(.medium))
            }
          }
        }
      } else {
        UploadMenu(media: media.map(\.mediaType)) {
          ZStack {
            GridItemBackground()
            VStack(spacing: 6) {
              Image(systemName: "plus")
                .imageScale(.large)
              Text(.imgly.localized("ly_img_editor_asset_library_button_add"))
                .font(.caption.weight(.medium))
            }
          }
        }
      }
    }
    .tint(.primary)
  }

  public var body: some View {
    ImageGrid { _ in
      emptyView
    } first: {
      firstAddButton
    }
    .onAppear(perform: updateConfiguration)
    .imgly.photoRoll(
      isPresented: $showImagePicker,
      media: media.map(\.mediaType),
      maxSelectionCount: maxSelectionCount,
      onComplete: mediaCompletion,
    )
  }

  private func updateConfiguration() {
    configuration.isSearchAllowed = false
  }

  private func makeEmptyStateButton(action: @escaping () -> Void, label: () -> some View) -> some View {
    Button(action: action) {
      label()
        .padding([.leading, .trailing], 40)
        .padding([.top, .bottom], 6)
    }
    .buttonStyle(.bordered)
    .font(.headline)
    .tint(.accentColor)
  }
}
