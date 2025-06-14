import SwiftUI

struct ResizeOverlay: View {
  @Environment(\.dismiss) var dismiss
  @StateObject private var viewModel: ViewModel

  init(interactor: Interactor, dimensions: PageDimensions) {
    _viewModel = .init(wrappedValue: .init(interactor: interactor, dimensions: dimensions))
  }

  var body: some View {
    AlertView(title: "Resize", content: {
      let aspectSet = viewModel.aspect != nil
      ScrollView {
        VStack(alignment: .leading) {
          Button {
            viewModel.updateAspect()
          } label: {
            Label(title: {
              Text(.init("Resize Proportionally"))
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
            textField(title: "Width", text: $viewModel.width)
              .accessibilityLabel("Width")
            textField(title: "Height", text: $viewModel.height)
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

  @ViewBuilder private func textField(title: String, text: Binding<CGFloat>) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("\(title) (\(viewModel.designUnit.description))")
        .font(.caption)

      TextField(.init(title), value: text, formatter: viewModel.numberFormatter)
        .keyboardType(.decimalPad)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
  }

  @ViewBuilder private func designUnitPicker() -> some View {
    let data: [Interactor.DesignUnit] = [.in, .mm, .px]
    ResizePicker(title: "Unit", data: data, selection: $viewModel.designUnit) { element in
      Text(element.label)
    } label: { element in
      element?.label ?? ""
    }
  }

  @ViewBuilder private func pixelScaleView() -> some View {
    let isPx = viewModel.designUnit == .px
    let formatExtension = isPx ? "x" : "dpi"
    ResizePicker(
      title: isPx ? "Pixel Scale" : "Resolution",
      data: isPx ? viewModel.pixelScaleValues : viewModel.resolutionValues,
      selection: isPx ? $viewModel.pixelScale : $viewModel.dpi
    ) { element in
      Text(viewModel.formatValue(element) + formatExtension)
    } label: { element in
      viewModel.formatValue(element ?? 0) + formatExtension
    }
  }
}
