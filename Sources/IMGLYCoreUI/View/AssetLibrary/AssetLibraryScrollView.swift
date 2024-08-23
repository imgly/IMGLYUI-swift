import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct AssetLibraryScrollView<Content: View>: View {
  var axis = Axis.Set.vertical
  var showsIndicators = true
  @ViewBuilder let content: Content

  @EnvironmentObject private var searchState: AssetLibrarySearchState
  @StateObject private var gestureHelper = GestureHelper()

  private var isDragging: Bool {
    switch gestureHelper.state {
    case .began, .changed: true
    default: false
    }
  }

  var body: some View {
    ScrollView(axis, showsIndicators: showsIndicators) {
      content
    }
    .introspect(.scrollView, on: .iOS(.v16...)) {
      // Workaround since `.simultaneousGesture(DragGesture().updating{}.onEnded{})` are not triggered on ended.
      $0.panGestureRecognizer.addTarget(gestureHelper,
                                        action: #selector(GestureHelper.handleGesture(_:)))
    }
    .onChange(of: isDragging) { newValue in
      if newValue, searchState.isPresented {
        Task {
          // Make transition a little smoother.
          try await Task.sleep(for: .milliseconds(200))
          searchState.isPresented = false
        }
      }
    }
  }
}

struct AssetLibraryScrollView_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
