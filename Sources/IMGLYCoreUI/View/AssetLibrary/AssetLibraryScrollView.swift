import Introspect
import SwiftUI

struct AssetLibraryScrollView<Content: View>: View {
  var axis = Axis.Set.vertical
  var showsIndicators = true
  @ViewBuilder let content: Content

  @EnvironmentObject private var searchState: AssetLibrarySearchState
  @StateObject private var gestureHelper = GestureHelper()

  private var isDragging: Bool {
    switch gestureHelper.state {
    case .began, .changed: return true
    default: return false
    }
  }

  var body: some View {
    ScrollView(axis, showsIndicators: showsIndicators) {
      content
        .introspectScrollView {
          // Workaround since `.simultaneousGesture(DragGesture().updating{}.onEnded{})` are not triggered on ended.
          $0.panGestureRecognizer.addTarget(gestureHelper,
                                            action: #selector(GestureHelper.handleGesture(_:)))
        }
    }
    .onChange(of: isDragging) { newValue in
      if newValue, searchState.isPresented {
        Task {
          // Make transition a little smoother.
          try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 200)
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
