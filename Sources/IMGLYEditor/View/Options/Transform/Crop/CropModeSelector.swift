import SwiftUI
@_spi(Internal) import IMGLYCore

struct CropModeSelector: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    let selection: Binding<ContentFillMode?> = interactor.bind(id, property: .key(.contentFillMode))

    CropModePicker(groups: [[.Crop, .Cover], [.Contain]], selection: selection)
      .accessibilityLabel("Crop Mode")
  }
}

struct CropModePicker: View {
  let groups: [[ContentFillMode]]
  @Binding var selection: ContentFillMode?

  var body: some View {
    Menu {
      ForEach(groups.indices, id: \.self) { index in
        // Create a separate picker for each group in
        // order to correctly apply the divider between
        // the sections.
        // Otherwise, we could not use the custom picker label
        // or the custom menu label.
        Picker("", selection: $selection) {
          ForEach(groups[index], id: \.self) { mode in
            Label {
              Text(mode.description)
            } icon: {
              icon(for: mode)
            }
            .tag(mode)
          }
        }
        .pickerStyle(.inline)
      }
    } label: {
      if let selection {
        HStack(spacing: 4) {
          icon(for: selection)
            .foregroundColor(.primary)
          Text(selection.description)
        }
        .transaction { transaction in
          transaction.animation = nil
        }
      }
    }
    .foregroundStyle(.primary)
    .environment(\.menuOrder, .fixed)
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder private func icon(for mode: ContentFillMode?) -> some View {
    if let imageName = mode?.imageName {
      if mode?.isSystemImage == true {
        Image(systemName: imageName)
      } else {
        Image(imageName, bundle: .module)
      }
    } else {
      EmptyView()
    }
  }
}
