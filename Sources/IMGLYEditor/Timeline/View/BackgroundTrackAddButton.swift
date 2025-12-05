import SwiftUI
@_spi(Internal) import IMGLYCore

/// A call-to-action button that sits next to the timeline and opens a menu.
struct BackgroundTrackAddButton: View {
  @EnvironmentObject var interactor: AnyTimelineInteractor
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  private var clipOptions: [AddClipOption] {
    AddClipOption.defaultOptions
  }

  var body: some View {
    // Don't render anything if no options
    if clipOptions.isEmpty {
      EmptyView()
    } else {
      buttonContent
        .padding(.horizontal)
        .frame(height: configuration.backgroundTrackHeight)
        .buttonStyle(.plain)
        .font(.caption)
        .fontWeight(.semibold)
        .background(buttonBackground)
        .overlay(buttonBorder)
        .fixedSize(horizontal: true, vertical: false)
    }
  }

  // MARK: - Button Content

  @ViewBuilder
  private var buttonContent: some View {
    if clipOptions.count == 1, let option = clipOptions.first {
      Button { perform(option) } label: { buttonLabel }
    } else {
      multipleOptionsMenu
    }
  }

  // MARK: - Button Components

  private var multipleOptionsMenu: some View {
    Menu(content: {
      ForEach(clipOptions, id: \.self) { option in
        menuItem(for: option)
      }
    }, label: {
      buttonLabel
    })
    .menuOrder(.fixed)
  }

  @ViewBuilder
  private var buttonLabel: some View {
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

  private var buttonBackground: some View {
    RoundedRectangle(cornerRadius: configuration.cornerRadius)
      .fill(Color(uiColor: .systemGray6))
  }

  private var buttonBorder: some View {
    RoundedRectangle(cornerRadius: configuration.cornerRadius)
      .inset(by: 0.25)
      .stroke(Color(uiColor: .separator), lineWidth: 0.5)
  }

  // MARK: - Actions

  private func perform(_ option: AddClipOption) {
    switch option {
    case .camera:
      interactor.openCamera(EditorEvents.AddFrom.defaultAssetSourceIDs)
    case .library:
      interactor.addAssetToBackgroundTrack()
    }
  }

  @ViewBuilder
  private func menuItem(for option: AddClipOption) -> some View {
    Button { perform(option) } label: {
      Label {
        Text(option.displayName)
      } icon: {
        if option.iconName.hasPrefix("custom.") {
          Image(option.iconName, bundle: .module)
        } else {
          Image(systemName: option.iconName)
        }
      }
    }
  }
}
