import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct ResizeOverlay: View {
  @Environment(\.dismiss) var dismiss
  @StateObject private var viewModel: ViewModel

  init(interactor: Interactor, dimensions: PageDimensions) {
    _viewModel = .init(wrappedValue: .init(interactor: interactor, dimensions: dimensions))
  }

  var body: some View {
    AlertView(title: .imgly.localized("ly_img_editor_dialog_resize_title"), content: {
      let aspectSet = viewModel.aspect != nil
      ScrollView {
        VStack(alignment: .leading) {
          Button {
            viewModel.updateAspect()
          } label: {
            Label(title: {
              Text(.imgly.localized("ly_img_editor_dialog_resize_button_resize_proportionally"))
                .foregroundStyle(.primary)
            }, icon: {
              Image(systemName: aspectSet ? "lock.fill" : "lock.open")
                .foregroundStyle(.primary)
                .font(.subheadline)
                .fontWeight(.semibold)
            })
            .padding(EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14))
            .background(aspectSet ? Color.accentColor.opacity(0.15) : .secondary.opacity(0.12))
            .clipShape(Capsule())
          }
          .foregroundStyle(.primary)
          HStack(alignment: .bottom, spacing: 8) {
            textField(
              title: .imgly.localized("ly_img_editor_dialog_resize_label_width \(viewModel.designUnit.abbreviation)"),
              textFieldTitle: "Width",
              text: $viewModel.width,
            )
            .accessibilityLabel("Width")
            textField(
              title: .imgly.localized("ly_img_editor_dialog_resize_label_height \(viewModel.designUnit.abbreviation)"),
              textFieldTitle: "Height",
              text: $viewModel.height,
            )
            .accessibilityLabel("Height")
          }
          .padding(.vertical, 8)
          Divider()
          HStack(spacing: 8) {
            designUnitPicker()
            pixelScaleView()
          }
          .padding(.vertical, 8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
      }
      .fixedSize(horizontal: false, vertical: true)
    }, apply: viewModel.apply)
  }

  @ViewBuilder private func textField(
    title: LocalizedStringResource,
    textFieldTitle: LocalizedStringResource,
    text: Binding<CGFloat>,
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)

      TextField(value: text, formatter: viewModel.numberFormatter) {
        Text(textFieldTitle)
      }
      .keyboardType(.decimalPad)
      .padding(.horizontal, 10)
      .frame(height: 34)
      .background(Color(.tertiarySystemFill))
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
  }

  @ViewBuilder private func designUnitPicker() -> some View {
    let data: [Interactor.DesignUnit] = [.in, .mm, .px]
    ResizePicker(
      title: .imgly.localized("ly_img_editor_dialog_resize_label_unit"),
      data: data,
      selection: $viewModel.designUnit,
    ) { element in
      Text(element.localizedStringResource)
    } label: { element in
      if let element {
        element.localizedStringResource
      } else {
        ""
      }
    }
  }

  @ViewBuilder private func pixelScaleView() -> some View {
    let isPx = viewModel.designUnit == .px
    let formatExtension = isPx ? "x" : "dpi"
    ResizePicker(
      title: isPx ? .imgly.localized("ly_img_editor_dialog_resize_label_pixel_scale") : .imgly
        .localized("ly_img_editor_dialog_resize_label_resolution"),
      data: isPx ? viewModel.pixelScaleValues : viewModel.resolutionValues,
      selection: isPx ? $viewModel.pixelScale : $viewModel.dpi,
    ) { element in
      Text(viewModel.formatValue(element) + formatExtension)
    } label: { element in
      "\(viewModel.formatValue(element ?? 0) + formatExtension)"
    }
  }
}
