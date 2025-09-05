import IMGLYCore
import SwiftUI

/// A grid view that displays photo roll assets from the user's photo library with an add button as the first item
/// to allow importing additional media.
public struct PhotoRollDestination: View {
  @EnvironmentObject private var configuration: AssetLibrarySectionConfiguration

  /// Creates a grid view of photo roll assets with add functionality.
  public init() {}

  private var emptyView: some View {
    VStack(spacing: 30) {
      if PhotoLibraryAuthorizationManager.shared.isAuthorized {
        Message.noElements

        PhotoRollAddMenu {
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
    }
  }

  private var firstAddButton: some View {
    PhotoRollAddMenu {
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
    .tint(.primary)
  }

  public var body: some View {
    ImageGrid { _ in
      emptyView
    } first: {
      firstAddButton
    }
    .onAppear(perform: updateConfiguration)
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
