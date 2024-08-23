@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct PageOverview: View {
  @EnvironmentObject private var interactor: Interactor

  var body: some View {
    PageGrid(pages: $interactor.pageOverview.pages, currentPage: $interactor.pageOverview.currentPage)
  }
}

struct PageOverviewState: Equatable {
  var currentPage: Interactor.BlockID?
  var pages: [Page] = []
}

extension PageOverviewState: CustomStringConvertible {
  var description: String {
    "\(currentPage ?? 0) \(pages.map(\.block))"
  }
}

struct Page: Identifiable, Equatable {
  var id: String { uuid }

  let uuid: String
  let block: Interactor.BlockID
  let width: CGFloat
  let height: CGFloat
  let refresh: UUID
}

private struct PageGrid: View {
  @EnvironmentObject private var interactor: Interactor

  @Binding var pages: [Page]
  @Binding var currentPage: Interactor.BlockID?

  @Namespace private var addPageThumbnailID
  @State private var minThumbnailHeight: CGFloat?
  @State private var draggedPage: Page?
  @State private var pagesOnDrag: [Page] = []

  @ViewBuilder private var addPageThumbnailButton: some View {
    SelectableItem(title: "", selected: false) {
      Button {
        interactor.actionButtonTapped(for: .addPage(interactor.pageCount))
      } label: {
        AddPageThumbnail()
      }
      .buttonStyle(.plain)
      .frame(minHeight: minThumbnailHeight)
    }
    .id(addPageThumbnailID)
  }

  func currentPageOrAddPageThumbnail(pages: [Page]? = nil, currentPage: Interactor.BlockID? = nil) -> any Hashable {
    let pages = pages ?? self.pages
    let currentPage = currentPage ?? self.currentPage

    if pages.last?.block == currentPage {
      return addPageThumbnailID
    } else {
      return currentPage
    }
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 159, maximum: 300), spacing: 16)], spacing: 16) {
          ReorderableForEach(pages, active: $draggedPage) { page in
            if let pageIndex = pages.firstIndex(of: page) {
              let isSelected = page.block == currentPage
              let title = LocalizedStringKey("Page \(pageIndex + 1)")
              SelectableItem(title: title, selected: isSelected) {
                PageThumbnail(page: page, isSelected: isSelected)
                  .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 8))
                  .onTapGesture {
                    currentPage = page.block
                  }
                  .simultaneousGesture(TapGesture(count: 2).onEnded {
                    interactor.isPageOverviewShown = false
                  })
                  .accessibilityLabel(title)
              }
              .id(page.block)
            }
          } moveAction: { from, to in
            pages.move(fromOffsets: from, toOffset: to)
          }
          .onChange(of: draggedPage) { newValue in
            if let newValue {
              currentPage = newValue.block
              pagesOnDrag = pages
            } else if pagesOnDrag != pages {
              interactor.addUndoStep()
            }
          }

          addPageThumbnailButton
        }
        .onPreferenceChange(ThumbnailMinHeightKey.self) { minThumbnailHeight = $0 }
        .padding([.leading, .trailing], 16)
      }
      // Extra inset instead of padding for `scrollTo`
      .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: 16) }
      .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 16) }
      .background {
        Color(uiColor: .systemGroupedBackground)
          .ignoresSafeArea()
      }
      .task {
        proxy.scrollTo(currentPageOrAddPageThumbnail(), anchor: .center)
      }
      .onChange(of: pages) { newValue in
        withAnimation {
          proxy.scrollTo(currentPageOrAddPageThumbnail(pages: newValue))
        }
      }
      .onChange(of: currentPage) { newValue in
        withAnimation {
          proxy.scrollTo(currentPageOrAddPageThumbnail(currentPage: newValue))
        }
      }
      .imgly.reorderableForEachContainer(active: $draggedPage)
      .animation(.default, value: pages)
    }
  }
}

private struct AddPageThumbnail: View {
  @ScaledMetric private var circleDiameter = 32
  private var fillColor = Color(.systemFill)

  var body: some View {
    ZStack {
      Color(.systemGray6)
      Image(systemName: "plus")
        .font(.title3)
        .frame(width: circleDiameter, height: circleDiameter)
        .background {
          Circle()
            .fill(fillColor)
        }
    }
    .cornerRadius(8)
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .inset(by: 1)
        .stroke(fillColor, lineWidth: 2)
    }
  }
}

private struct PageThumbnail: View {
  @EnvironmentObject private var interactor: Interactor

  let page: Page
  let isSelected: Bool
  @State private var image: (value: UIImage, refresh: UUID)?
  @State private var width: CGFloat?
  private let minHeight: CGFloat = 100
  private let maxHeight: CGFloat = 288

  private var isInitialLoading: Bool { image == nil }

  // Should be optional to properly propose the `idealHeight` and thus `height` derived from measured `width`.
  private var idealHeight: CGFloat? {
    // The "correct" behavior would be to return nil if width is nil but we assume some reasonable width (for smallest
    // screen, iPhone SE) until the correct width is measured to avoid fast scrolling hiccups with many pages.
    let width: CGFloat? = width ?? 155.5
    guard let width else {
      return nil
    }
    // Rounding to actual screen pixels instead of point would be more accurate.
    return (width * (page.height / page.width)).rounded()
  }

  private var height: CGFloat? {
    guard let idealHeight else {
      return nil
    }
    return max(min(idealHeight, maxHeight), minHeight)
  }

  private var debounceDuration: Duration {
    switch (isInitialLoading, isSelected) {
    case (true, true):
      .zero
    case (true, false):
      .milliseconds(10)
    case (false, true):
      .milliseconds(200)
    case (false, false):
      .milliseconds(250)
    }
  }

  var body: some View {
    ZStack {
      if let image {
        GridItemBackground()
        Image(uiImage: image.value)
      } else {
        GridItemBackground()
          .imgly.shimmer()
      }
    }
    .frame(width: width, height: height)
    .preference(key: ThumbnailMinHeightKey.self, value: height)
    .background {
      GeometryReader { geo in
        Color.clear
          .preference(key: ThumbnailWidthKey.self, value: geo.size.width)
          .onAppear {
            // Fixes `onPreferenceChange(ThumbnailWidthKey.self)` is sometimes not called when the thumbnail gets
            // recreated.
            width = geo.size.width
          }
      }
    }
    .onPreferenceChange(ThumbnailWidthKey.self) { width = $0 }
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .task(id: page.refresh) {
      let refresh = page.refresh
      guard image?.refresh != refresh else {
        return
      }
      guard let idealHeight else {
        return
      }
      do {
        // Debounce with "priority" to keep moving pages and scrolling smooth as generating thumbnails will put high
        // preasure on the main thread for a very short moment. `AsyncChannel` from swift-async-algorithms could be used
        // to serialize thumbnail requests. Selectively updating `page.refresh` would also help (see
        // `PageOverviewState.init(from engine:)`).
        try await Task.sleep(for: debounceDuration)
        try Task.checkCancellation()
        // Clamp ideal height only by `maxHeight` and not by `minHeight` to make the resulting image fit and match
        // screen pixels!
        let clampedHeight = min(idealHeight, maxHeight)
        let image = try await interactor.generatePageThumbnail(page.block, height: clampedHeight)
        try Task.checkCancellation()
        if isInitialLoading {
          withAnimation(.linear(duration: 0.15)) {
            self.image = (image, refresh)
          }
        } else {
          self.image = (image, refresh)
        }
      } catch {}
    }
  }
}

private struct ThumbnailWidthKey: PreferenceKey {
  static let defaultValue: CGFloat? = nil
  static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    value = value ?? nextValue()
  }
}

private struct ThumbnailMinHeightKey: PreferenceKey {
  static let defaultValue: CGFloat? = nil
  static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    let thisValue = value
    let nextValue = nextValue()
    if let thisValue, let nextValue {
      value = min(thisValue, nextValue)
    } else {
      value = thisValue ?? nextValue
    }
  }
}

struct PageOverview_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
