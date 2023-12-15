@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct Canvas: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  let zoomPadding: CGFloat

  static let safeCoordinateSpaceName = "safeCanvas"
  static let safeCoordinateSpace = CoordinateSpace.named(safeCoordinateSpaceName)

  @Environment(\.verticalSizeClass) private var verticalSizeClass

  private let viewDebugging = false

  private var bottomBarHeight: CGFloat {
    let safeAreaInsetHeight: CGFloat = verticalSizeClass == .compact ? 33 : BottomBarLabelStyle.size.height
    let paddingTop: CGFloat = 8 + (barContentGeometry?.safeAreaInsets.top ?? 0)
    let paddingBottom: CGFloat = 8

    return safeAreaInsetHeight + paddingTop + paddingBottom
  }

  private var safeAreaInsetHeight: CGFloat {
    if interactor.editMode != .text {
      return bottomBarHeight
    } else {
      return keyboardToolbarHeight
    }
  }

  @State private var barContentGeometry: Geometry?
  @State private var bottomSafeAreaInset: CGFloat = 0
  @State private var keyboardToolbarHeight: CGFloat = 0

  @ViewBuilder func bottomBar(type: SheetType?) -> some View {
    BottomBar(type: type, id: id, height: bottomBarHeight, bottomSafeAreaInset: bottomSafeAreaInset)
  }

  @ViewBuilder var canvas: some View {
    ZStack {
      if viewDebugging {
        Color.red.opacity(0.2).border(.red).padding(5)
      }
      interactor.canvas
        .imgly.canvasAction(anchor: .top) {
          CanvasMenu()
        }
    }
  }

  @ViewBuilder var measureGeometry: some View {
    ZStack {
      if viewDebugging {
        Color.blue.opacity(0.2).border(.blue).allowsHitTesting(false)
      } else {
        Color.clear
      }
    }
    .coordinateSpace(name: Self.safeCoordinateSpaceName)
    .background {
      GeometryReader { safeCanvas in
        Color.clear
          .preference(key: CanvasGeometryKey.self, value: Geometry(safeCanvas, .local))
      }
    }
  }

  var body: some View {
    ZStack {
      canvas
        .ignoresSafeArea()
      measureGeometry
    }
    .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: zoomPadding) }
    .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: zoomPadding) }
    .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: zoomPadding) }
    .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: zoomPadding) }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if interactor.isEditing {
        ZStack {
          if viewDebugging {
            Color.green.opacity(0.2).border(.green).ignoresSafeArea()
          } else {
            Color.clear
          }
        }
        .frame(height: safeAreaInsetHeight)
        .transition(.move(edge: .bottom))
      }
    }
    .overlay(alignment: .bottom) {
      VStack {
        Spacer()
        if interactor.isEditing {
          ZStack {
            bottomBar(type: nil)
              .disabled(interactor.sheet.isPresented)
              .onPreferenceChange(BottomBarContentGeometryKey.self) { newValue in
                barContentGeometry = newValue
              }
            Group {
              if let type = interactor.sheetTypeForSelection {
                bottomBar(type: type)
                  .zIndex(1)
                  .transition(.move(edge: .bottom))
              }
            }
            .animation(.easeInOut(duration: 0.2), value: interactor.sheetTypeForSelection)
          }
          .transition(.move(edge: .bottom))
        }
      }
      .ignoresSafeArea(.keyboard)
    }
    .overlay(alignment: .bottom) {
      KeyboardToolbar()
        .onPreferenceChange(KeyboardToolbarSafeAreaInsetsKey.self) { newValue in
          if newValue?.top != 0 {
            keyboardToolbarHeight = newValue?.top ?? 0
          }
        }
    }
    .background {
      GeometryReader { geo in
        Color.clear
          .preference(key: CanvasSafeAreaInsetsKey.self, value: geo.safeAreaInsets)
      }
      .ignoresSafeArea(.keyboard)
    }
    .onPreferenceChange(CanvasSafeAreaInsetsKey.self) { newValue in
      bottomSafeAreaInset = newValue?.bottom ?? 0
    }
    .onChange(of: verticalSizeClass) { newValue in
      interactor.verticalSizeClass = newValue
    }
  }
}

private struct CanvasSafeAreaInsetsKey: PreferenceKey {
  static let defaultValue: EdgeInsets? = nil
  static func reduce(value: inout EdgeInsets?, nextValue: () -> EdgeInsets?) {
    value = value ?? nextValue()
  }
}

struct Canvas_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
