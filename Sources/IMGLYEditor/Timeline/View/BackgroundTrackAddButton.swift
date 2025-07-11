import SwiftUI

/// A call-to-action button that sits next to the timeline and opens a menu.
struct BackgroundTrackAddButton: View {
  @EnvironmentObject var interactor: AnyTimelineInteractor
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  var body: some View {
    Menu {
      Button {
        interactor.openCamera(EditorEvents.AddFrom.defaultAssetSourceIDs)
      } label: {
        Label {
          Text(.imgly.localized("ly_img_editor_timeline_add_clip_option_camera"))
        } icon: {
          Image("custom.camera.fill.badge.plus", bundle: .module)
        }
      }
      Button {
        interactor.openImagePicker(EditorEvents.AddFrom.defaultAssetSourceIDs)
      } label: {
        Label {
          Text(.imgly.localized("ly_img_editor_timeline_add_clip_option_photo_roll"))
        } icon: {
          Image("custom.photo.fill.on.rectangle.fill.badge.plus", bundle: .module)
        }
      }
      Button {
        interactor.addAssetToBackgroundTrack()
      } label: {
        Label {
          Text(.imgly.localized("ly_img_editor_timeline_add_clip_option_library"))
        } icon: {
          Image(systemName: "play.square.stack")
        }
      }
    } label: {
      HStack {
        Label {
          Text(.imgly.localized("ly_img_editor_timeline_button_add_clip"))
        } icon: {
          Image(systemName: "plus")
        }
        Spacer()
      }
      .frame(minWidth: 100)
      .frame(maxHeight: .infinity)
      .contentShape(Rectangle())
    }
    .menuOrder(.fixed)
    .padding(.horizontal)
    .frame(height: configuration.backgroundTrackHeight)
    .buttonStyle(.plain)
    .font(.caption)
    .fontWeight(.semibold)
    .background {
      RoundedRectangle(cornerRadius: configuration.cornerRadius)
        .fill(Color(uiColor: .systemGray6))
    }
    .overlay {
      RoundedRectangle(cornerRadius: configuration.cornerRadius)
        .inset(by: 0.25)
        .stroke(Color(uiColor: .separator), lineWidth: 0.5)
    }
    .fixedSize(horizontal: true, vertical: false)
  }
}
