@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct TransformOptions<Item: View>: View {
  @Environment(\.imglySelection) private var id
  @StateObject private var searchState = AssetLibrarySearchState()
  @StateObject private var viewModel: ViewModel

  let sources: [AssetLoader.SourceData]
  let mode: TransformMode
  let interactor: Interactor
  @ViewBuilder var item: (AssetItem) -> Item

  private var isForceCropActive: Bool {
    interactor.isForceCropActive(for: id)
  }

  init(
    interactor: Interactor,
    item: @escaping (AssetItem) -> Item,
    sources: [AssetLoader.SourceData],
    mode: TransformMode = .cropAndResize
  ) {
    self.interactor = interactor
    self.item = item
    self.sources = sources
    self.mode = mode
    _viewModel = StateObject(wrappedValue: ViewModel(interactor: interactor, sources: sources))
  }

  var body: some View {
    VStack {
      AssetGrid { asset in
        item(asset)
      } empty: { _ in
        Message.noElements
      } more: {
        EmptyView()
      }
      .imgly.assetGrid(axis: .horizontal)
      .imgly.assetGrid(items: [GridItem(.flexible(minimum: 72, maximum: 120))])
      .imgly.assetGrid(spacing: 8)
      .imgly.assetGrid(edges: [.leading, .trailing])
      .imgly.assetGrid(padding: 16)
      .imgly.assetGridPlaceholderCount { _, _ in
        10
      }
      .imgly.assetGrid(messageTextOnly: true)
      .imgly.assetGrid(sourcePadding: 16)
      .imgly.assetGrid(shouldShowSingleItem: false)
      .imgly.assetLoader(sources: viewModel.sources, search: $viewModel.query, order: .sorted, perPage: 65)
      .environmentObject(searchState)
      .frame(height: viewModel.assetGridHeight)
      Spacer()
      Divider()
      categorySelection
        .padding(.bottom, 16)
    }
    .background(Color(.systemGroupedBackground))
    .task {
      viewModel.loadGroups()
    }
    .imgly.alert($viewModel.alertPresented, content: {
      if let pageDimenstions = viewModel.dimensions {
        ResizeOverlay(interactor: interactor, dimensions: pageDimenstions)
      } else {
        EmptyView()
      }
    })
  }

  @ViewBuilder private var categorySelection: some View {
    if isForceCropActive || viewModel.groups.count <= 1 {
      HStack {
        Spacer()
        CropModeSelector()
        Spacer()
      }
    } else {
      if let dimensions = viewModel.dimensions {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            Spacer().frame(width: 20)
            if interactor.editMode == .crop {
              CropModeSelector()
            }
            if mode != .crop, !isForceCropActive {
              HStack {
                Image("custom.arrow.down.left.and.arrow.up.right", bundle: .module)
                Text("\(Int(dimensions.width)) × \(Int(dimensions.height)) \(dimensions.designUnit.abbreviation)")
                  .clipShape(Rectangle())
              }
              .font(.subheadline)
              .padding(.vertical, 7)
              .padding(.horizontal, 14)
              .onTapGesture {
                viewModel.alertPresented = true
              }
              .accessibilityLabel("Dimensions")
              .accessibilityAddTraits(.isButton)
            }
            Divider()
              .frame(height: 30)
            ForEach(viewModel.groups, id: \.self) { group in
              groupItem(group)
            }
            Spacer()
              .frame(width: 20)
          }
        }
      } else {
        EmptyView()
      }
    }
  }

  @ViewBuilder func groupItem(_ id: String) -> some View {
    let isSelected = viewModel.selectedGroup == id

    Button {
      viewModel.selectedGroup = id
    } label: {
      Text(id.capitalized)
        .font(.subheadline)
        .fontWeight(isSelected ? .bold : .regular)
        .padding(EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14))
        .background(
          viewModel.selectedGroup == id ? Color.accentColor.opacity(0.15) : .clear,
        )
        .foregroundStyle(isSelected ? Color.accentColor : .primary)
        .clipShape(Capsule())
    }
  }
}
