@_spi(Internal) import IMGLYCore
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

/// A scale picker a.k.a. sliding ruler that picks values at its center position. A cursor view is not part of it for
/// best versatility. A cursor can be added with a centered overlay. See `MeasurementScalePicker` or
/// `ScalePicker_Previews` for examples.
@_spi(Internal) public struct ScalePicker<V>: View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
  @_spi(Internal) public init(value: Binding<V>,
                              in bounds: ClosedRange<V>,
                              neutralValue: V? = nil,
                              tickStep: V.Stride = 1,
                              tickSpacing: CGFloat = 8,
                              onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
    _storedValue = .init(initialValue: value.wrappedValue)
    _bindingValue = value
    self.bounds = .init(uncheckedBounds: (lower: CGFloat(bounds.lowerBound), upper: CGFloat(bounds.upperBound)))
    self.neutralValue = neutralValue
    self.tickStep = tickStep
    self.tickSpacing = tickSpacing
    self.onEditingChanged = onEditingChanged
    if let neutralValue, bounds.contains(neutralValue) {
      let neg: StrideThrough<V> = Swift.stride(from: neutralValue, through: bounds.lowerBound, by: -tickStep)
      let pos: StrideThrough<V> = Swift.stride(from: neutralValue, through: bounds.upperBound, by: tickStep)
      let negTicks = neg.enumerated().map { (-$0, $1) }
      let posTicks = pos.enumerated().map { ($0, $1) }
      ticks = negTicks.dropFirst().reversed() + posTicks
      leadingRemainder = (bounds.lowerBound ... neutralValue).length.truncatingRemainder(dividingBy: V(tickStep))
      trailingRemainder = (neutralValue ... bounds.upperBound).length.truncatingRemainder(dividingBy: V(tickStep))
    } else {
      let stride: StrideThrough<V> = Swift.stride(from: bounds.lowerBound, through: bounds.upperBound, by: tickStep)
      ticks = stride.enumerated().map { ($0, $1) }
      leadingRemainder = 0
      trailingRemainder = bounds.length.truncatingRemainder(dividingBy: V(tickStep))
    }
  }

  // The stored value is required to store arbitrary values
  // since the scroll view can only represent values aligned with pixels.
  @State var storedValue: V
  @Binding var bindingValue: V
  let bounds: ClosedRange<CGFloat>
  let neutralValue: V?
  let tickStep: V.Stride
  let onEditingChanged: (Bool) -> Void

  let height: CGFloat = 44
  let ticks: [(tick: Int, value: V)]
  let tickWidth: CGFloat = 2
  let tickSpacing: CGFloat
  var tickCell: CGFloat { tickWidth + tickSpacing }
  var ptPerValue: CGFloat { tickCell / CGFloat(tickStep) }
  let leadingRemainder: V
  let trailingRemainder: V

  @ViewBuilder func largeTick(value _: V) -> some View {
    Capsule().frame(width: tickWidth, height: 6)
  }

  @ViewBuilder func smallTick(value _: V) -> some View {
    Capsule().frame(width: tickWidth, height: 2)
  }

  // We don’t use Introspect’s @Weak property wrapper here because it releases too quickly
  @State var scrollView: UIScrollView?
  @State var scrollViewWidth: CGFloat?
  @State var contentGeometry: Geometry?
  @State var snapping = SnapState.disarmed

  enum SnapState {
    case disarmed, armed, snapped(distance: V)
  }

  @StateObject private var hapticsHelper = HapticsHelper()
  @StateObject private var gestureHelper = GestureHelper()

  var isInitialized: Bool { scrollView != nil && scrollViewWidth != nil && contentGeometry != nil }

  var isDragging: Bool {
    switch gestureHelper.state {
    case .began, .changed: true
    default: false
    }
  }

  var isInteracting: Bool {
    guard let scrollView else {
      return isDragging
    }
    return isDragging || scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating
  }

  var contentFrame: CGRect { contentGeometry?.frame ?? .zero }
  var contentWidth: CGFloat { contentFrame.width }
  var contentOffset: CGFloat { -contentFrame.minX }
  var contentPadding: CGFloat { ((scrollViewWidth ?? 0) - tickWidth) / 2 }
  var contentPaddingLeading: CGFloat { contentPadding + (CGFloat(leadingRemainder) * ptPerValue) }
  var contentPaddingTrailing: CGFloat { contentPadding + (CGFloat(trailingRemainder) * ptPerValue) }

  var scrollValue: CGFloat? {
    guard isInitialized, let scrollViewWidth else {
      return nil
    }
    let actualScrollWidth = contentWidth - scrollViewWidth
    return (contentOffset / actualScrollWidth) * bounds.length + bounds.lowerBound
  }

  func scrollTo(value: V, animated: Bool) {
    guard isInitialized, let scrollViewWidth, let scrollView else {
      return
    }
    storedValue = value
    let newValue = CGFloat(value).clamped(to: bounds)
    let actualScrollWidth = contentWidth - scrollViewWidth
    let contentOffset = (newValue - bounds.lowerBound) * actualScrollWidth / bounds.length
    scrollView.setContentOffset(CGPoint(x: contentOffset, y: scrollView.contentOffset.y), animated: animated)
  }

  func tickColor(value: V) -> AnyShapeStyle {
    guard let neutralValue else {
      return AnyShapeStyle(.primary)
    }
    let neutral = V(neutralValue)
    if storedValue < neutral, (storedValue ... neutral).contains(value) {
      return AnyShapeStyle(.tint)
    } else if neutral < storedValue, (neutral ... storedValue).contains(value) {
      return AnyShapeStyle(.tint)
    } else {
      return AnyShapeStyle(.primary)
    }
  }

  @ViewBuilder var ruler: some View {
    HStack(alignment: .center, spacing: tickSpacing) {
      ForEach(ticks, id: \.tick) { tick, value in
        Group {
          if tick % 5 == 0 {
            largeTick(value: value)
          } else {
            smallTick(value: value)
          }
        }
        .foregroundStyle(tickColor(value: value))
      }
    }
    .environment(\.layoutDirection, .leftToRight)
  }

  func tickCrossedOrReached(old: V, new: V) -> Bool {
    let offset = neutralValue ?? V(bounds.lowerBound)
    let old = (old - offset) / V(tickStep)
    let new = (new - offset) / V(tickStep)
    return integerCrossedOrReached(old: old, new: new)
  }

  func integerCrossedOrReached(old: V, new: V) -> Bool {
    guard new != old else {
      return false
    }
    let distanceMoreThanOne = abs(old - new) > 1
    let oldInt = old.rounded(.towardZero)
    let newInt = new.rounded(.towardZero)
    let exactOld = old == oldInt
    let exactNew = new == newInt
    let intChanged = oldInt != newInt
    return distanceMoreThanOne || exactNew || (!exactOld && intChanged)
  }

  func snapIfNeeded(_ newStoredValue: V) -> V {
    if isDragging, let neutralValue {
      let deltaInPt: CGFloat = 5
      let delta = V(deltaInPt / ptPerValue)
      let canSnap = ((neutralValue - delta) ... (neutralValue + delta)).contains(newStoredValue)
      let snapValue = V(CGFloat(neutralValue).clamped(to: bounds))
      switch snapping {
      case .disarmed:
        if !canSnap {
          snapping = .armed
        }
      case .armed:
        if canSnap {
          snapping = .snapped(distance: 0)
          scrollTo(value: snapValue, animated: false)
          hapticsHelper.impactOccurred()
          return snapValue
        }
      case let .snapped(distance):
        let disarmInPt: CGFloat = 20
        if CGFloat(abs(distance)) * ptPerValue >= disarmInPt {
          snapping = .disarmed
        } else {
          let offset = newStoredValue - storedValue
          snapping = .snapped(distance: distance - offset)
          scrollTo(value: snapValue, animated: false)
          return snapValue
        }
      }
    }

    if tickCrossedOrReached(old: storedValue, new: newStoredValue) {
      hapticsHelper.selectionChanged()
    }
    return newStoredValue
  }

  @ViewBuilder var slidingRuler: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      ruler
        .padding([.leading], contentPaddingLeading)
        .padding([.trailing], contentPaddingTrailing)
        .frame(height: height)
        .background {
          GeometryReader { geo in
            Color.clear
              .preference(key: ContentGeometryKey.self, value: Geometry(geo, rulerCoordinateSpace))
          }
        }
    }
    .introspect(.scrollView, on: .iOS(.v16...)) { newScrollView in
      // Check if we already have a reference to this UIScrollView
      guard newScrollView !== scrollView else { return }
      newScrollView.decelerationRate = .fast
      // Workaround since `.simultaneousGesture(DragGesture().updating{}.onEnded{})` are not triggered on ended.
      newScrollView.panGestureRecognizer.addTarget(gestureHelper,
                                                   action: #selector(GestureHelper.handleGesture(_:)))

      // Delay mutation until the next runloop.
      // https://github.com/siteline/SwiftUI-Introspect/issues/212#issuecomment-1590130815
      DispatchQueue.main.async {
        // Workaround to precisely set `contentOffset`.
        scrollView = newScrollView
      }
    }
    .coordinateSpace(name: rulerCoordinateSpaceName)
    .onPreferenceChange(ContentGeometryKey.self) { contentGeometry = $0 }
    .background {
      GeometryReader { geo in
        Color.clear
          .preference(key: ScrollViewWidthKey.self, value: geo.size.width)
      }
    }
    .onPreferenceChange(ScrollViewWidthKey.self) { scrollViewWidth = $0 }
    .onChange(of: scrollValue) { newValue in
      guard isInteracting, let newValue else {
        return
      }
      storedValue = snapIfNeeded(V(newValue.clamped(to: bounds)))
      guard storedValue != bindingValue else {
        return
      }
      bindingValue = storedValue
    }
    .onChange(of: bindingValue) { newValue in
      guard !isInteracting, storedValue != newValue else {
        return
      }
      storedValue = newValue
      scrollTo(value: newValue, animated: false)
    }
    .onChange(of: isInitialized) { newValue in
      if newValue {
        scrollTo(value: bindingValue, animated: false)
      }
    }
    .onChange(of: isInteracting) { newValue in
      if newValue {
        hapticsHelper.initialize()
      } else {
        hapticsHelper.deinitialize()
      }
      onEditingChanged(newValue)
    }
    .onChange(of: isDragging) { newValue in
      if !newValue {
        snapping = .disarmed
      }
    }
    .onChange(of: contentWidth) { _ in
      scrollTo(value: storedValue, animated: false)
    }
  }

  @_spi(Internal) public var body: some View {
    slidingRuler
      .frame(height: height)
  }
}

private let rulerCoordinateSpaceName = "ruler"
private let rulerCoordinateSpace = CoordinateSpace.named(rulerCoordinateSpaceName)

private struct ContentGeometryKey: PreferenceKey {
  static let defaultValue: Geometry? = nil
  static func reduce(value: inout Geometry?, nextValue: () -> Geometry?) {
    value = value ?? nextValue()
  }
}

private struct ScrollViewWidthKey: PreferenceKey {
  static let defaultValue: CGFloat? = nil
  static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    value = value ?? nextValue()
  }
}

private class HapticsHelper: ObservableObject {
  private var impact: UIImpactFeedbackGenerator?
  private var selection: UISelectionFeedbackGenerator?

  @MainActor func initialize() {
    if impact == nil {
      impact = UIImpactFeedbackGenerator(style: .light)
      impact?.prepare()
    }
    if selection == nil {
      selection = UISelectionFeedbackGenerator()
      selection?.prepare()
    }
  }

  func deinitialize() {
    impact = nil
    selection = nil
  }

  @MainActor func impactOccurred() {
    impact?.impactOccurred()
    impact?.prepare()
  }

  @MainActor func selectionChanged() {
    selection?.selectionChanged()
    selection?.prepare()
  }
}

struct ScalePicker_Previews: PreviewProvider {
  @ViewBuilder static var preview: some View {
    previewState(Float(20)) { binding in
      VStack {
        ScalePicker(value: binding, in: -10 ... 45).overlay { Capsule().frame(width: 2) }
        ScalePicker(value: binding, in: -45 ... 10, neutralValue: 0).overlay {
          VStack(spacing: -2) {
            Text("\(Int(binding.wrappedValue.rounded()))")
            Color.clear.frame(width: 4).border(.foreground)
          }
        }
        .foregroundColor(.red)
        .tint(.green)
        .background(.primary)
        List {
          let minus20 = Binding {
            binding.wrappedValue - 20
          } set: {
            binding.wrappedValue = $0 + 20
          }
          MeasurementScalePicker(value: minus20, unit: UnitAngle.degrees, in: -45 ... 45)
          MeasurementScalePicker(value: binding, unit: UnitAngle.degrees, in: -45 ... 45)
          Slider(value: binding, in: -45 ... 45)
        }
        .foregroundColor(.red)
        .tint(.green)
        Button("Random Float") {
          binding.wrappedValue = .random(in: -45 ... 45)
        }
        Button("Random Int") {
          binding.wrappedValue = Float(Int.random(in: -45 ... 45))
        }
        Stepper("Step 10", value: binding, step: 10)
      }
    }
  }

  static var previews: some View {
    preview
    preview.imgly.nonDefaultPreviewSettings()
  }
}
