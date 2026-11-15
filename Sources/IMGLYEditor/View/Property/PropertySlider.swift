@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

/// At the maximum the thumb overhangs the track, so the default spacing lets it
/// touch the readout. File scope, because a generic type has no static stored property.
private let readoutSpacing: CGFloat = 16

struct PropertySlider<T: MappedType & BinaryFloatingPoint>: View where T.Stride: BinaryFloatingPoint {
  let title: LocalizedStringResource
  let bounds: ClosedRange<T>
  let property: Property
  let mapping: Mapping
  let getter: Interactor.PropertyGetter<T>
  let setter: Interactor.PropertySetter<T>
  let propertyBlock: PropertyBlock?
  let selection: Interactor.BlockID?
  let defaultValue: T?
  let assetContext: EffectProperty.AssetContext?
  /// Explicit step override. `nil` defers to ``resolvedStep``.
  let step: T?
  /// Values that capture the drag, such as `0`. Ignored while one step is
  /// wider than the capture zone, about 6 pt.
  let detents: [T]
  /// For a range like `0.1...1`, where the percentage readout shows `0` at
  /// the non-zero minimum.
  let disableAutoPercentage: Bool
  /// Hides the value next to the track. VoiceOver still reads it.
  let showsReadout: Bool
  /// Drags without steps, for a non-linear `mapping`.
  let isContinuous: Bool

  private let extractValue: ((AssetProperty) -> T?)?
  private let buildUpdatedProperty: ((AssetProperty, T) -> AssetProperty?)?
  private let assetStep: T?

  typealias Mapping = (_ value: Binding<T>, _ bounds: ClosedRange<T>) -> Binding<T>

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  /// From the environment, so a call site cannot forget to pass it.
  @Environment(\.isEnabled) private var isEnabled
  @State private var localValue: T?
  @State private var assetValue: T
  @State private var detentState: SnapDetents<T>.State = .disarmed
  @State private var sliderWidth: CGFloat?
  @State private var impactGenerator: UIImpactFeedbackGenerator?

  // MARK: - Engine Property Initializer

  init(_ title: LocalizedStringResource, in bounds: ClosedRange<T>, step: T? = nil, property: Property,
       mapping: @escaping Mapping = { value, _ in value },
       setter: @escaping Interactor.PropertySetter<T> = Interactor.Setter.set(),
       getter: @escaping Interactor.PropertyGetter<T> = Interactor.Getter.get(),
       propertyBlock: PropertyBlock? = nil,
       selection: Interactor.BlockID? = nil,
       defaultValue: T? = nil,
       assetContext: EffectProperty.AssetContext? = nil,
       detents: [T] = [],
       disableAutoPercentage: Bool = false,
       showsReadout: Bool = true,
       isContinuous: Bool = false) {
    self.title = title
    self.bounds = bounds
    self.step = step
    self.property = property
    self.mapping = mapping
    self.setter = setter
    self.getter = getter
    self.propertyBlock = propertyBlock
    self.selection = selection
    self.defaultValue = defaultValue
    self.assetContext = assetContext
    self.detents = detents
    self.disableAutoPercentage = disableAutoPercentage
    self.showsReadout = showsReadout
    self.isContinuous = isContinuous

    if let assetContext {
      let closures = Self.assetClosures(for: assetContext.assetProperty)
      extractValue = closures.extractValue
      buildUpdatedProperty = closures.buildUpdatedProperty
      let initialValue = closures.extractValue(assetContext.assetProperty) ?? defaultValue ?? bounds.lowerBound
      _assetValue = State(initialValue: initialValue)
      assetStep = Self.extractStep(from: assetContext.assetProperty)
    } else {
      extractValue = nil
      buildUpdatedProperty = nil
      _assetValue = State(initialValue: defaultValue ?? bounds.lowerBound)
      assetStep = nil
    }
  }

  // MARK: - Engine Property Bindings

  private var binding: Binding<T> {
    interactor.bind(
      selection ?? id,
      propertyBlock,
      property: property,
      default: defaultValue ?? bounds.lowerBound,
      getter: getter,
      setter: setter,
      completion: nil,
    )
  }

  private var sliderBinding: Binding<T> {
    Binding(
      get: {
        localValue ?? binding.wrappedValue
      },
      set: { newValue in
        localValue = newValue
        binding.wrappedValue = newValue
      },
    )
  }

  // MARK: - Stepping and Detents

  /// Argument, then asset step, then 1% of the range, as on Web. VoiceOver and
  /// the readout use it even when ``isContinuous`` is set.
  private var resolvedStep: T {
    step ?? assetStep ?? PercentageSliderHelper.stepFromMinMax(min: bounds.lowerBound, max: bounds.upperBound)
  }

  /// ``detents`` on the step grid, so a captured value matches the readout.
  /// The clamp is needed: step `0.06` in `0...1` rounds `1.0` to `1.02`.
  ///
  /// - Important: The targets are in ``bounds`` space, but ``detentBinding``
  /// receives raw values. Do not combine detents with a non-identity `mapping`.
  private var alignedDetents: [T] {
    detents.map { detent in
      let aligned = NumberStepperMath.snapped(detent, step: resolvedStep, origin: bounds.lowerBound)
      return NumberStepperMath.clamped(aligned, to: bounds)
    }
  }

  /// From the rendered width, so the detent zones stay a fixed screen distance.
  private var pointsPerValue: CGFloat {
    guard let sliderWidth, bounds.upperBound > bounds.lowerBound else { return 0 }
    return sliderWidth / CGFloat(bounds.upperBound - bounds.lowerBound)
  }

  /// Like ``sliderBinding``, but routes the drag through ``SnapDetents``.
  private var detentBinding: Binding<T> {
    Binding(
      get: {
        localValue ?? binding.wrappedValue
      },
      set: { newValue in
        // A step wider than the capture zone already lands on the detent, and
        // the escape distance would make the steps beside it unreachable.
        let isFineGrid = CGFloat(resolvedStep) * pointsPerValue < SnapDetents<T>.captureZonePoints
        var snapMachine = SnapDetents(targets: isFineGrid ? alignedDetents : [], state: detentState)
        let advance = snapMachine.advance(rawValue: newValue, pointsPerValue: pointsPerValue)
        detentState = snapMachine.state
        localValue = advance.value
        binding.wrappedValue = advance.value
        if advance.didCapture {
          impactGenerator?.impactOccurred()
          impactGenerator?.prepare()
        }
      },
    )
  }

  /// One VoiceOver swipe, committed as one undo step.
  ///
  /// - Important: `value` must be in ``bounds`` space, so pass the binding the
  /// `Slider` gets. A raw stroke width of 10 would clamp into `-3…3` as 3.
  ///
  /// SwiftUI does not block a custom accessibility action on a disabled view,
  /// so this guards ``isEnabled``.
  private func adjustForAccessibility(_ direction: AccessibilityAdjustmentDirection, value: Binding<T>) {
    guard isEnabled else { return }
    switch direction {
    case .increment:
      value.wrappedValue = NumberStepperMath.stepped(
        value.wrappedValue, direction: .up, step: resolvedStep, bounds: bounds,
      )
    case .decrement:
      value.wrappedValue = NumberStepperMath.stepped(
        value.wrappedValue, direction: .down, step: resolvedStep, bounds: bounds,
      )
    @unknown default:
      return
    }
    interactor.addUndoStep()
  }

  // MARK: - Value Formatting

  private var showPercentage: Bool {
    !disableAutoPercentage && PercentageSliderHelper.isPercentageSlider(min: bounds.lowerBound, max: bounds.upperBound)
  }

  private func percentageText(for value: T) -> String {
    let percentage = PercentageSliderHelper.valueToPercentage(
      value: value, min: bounds.lowerBound, max: bounds.upperBound,
    )
    return "\(Int(percentage.rounded()))"
  }

  /// Uses ``resolvedStep``, so the decimals match the step the slider moves by.
  private func formattedText(for value: T) -> String {
    PercentageSliderHelper.formatValue(value: value, step: resolvedStep)
  }

  /// A bare number, as on Web. ``spokenText(for:)`` adds the `%`.
  private func displayText(for value: T) -> String {
    showPercentage ? percentageText(for: value) : formattedText(for: value)
  }

  private func spokenText(for value: T) -> String {
    showPercentage ? "\(percentageText(for: value))%" : formattedText(for: value)
  }

  // MARK: - Body

  var body: some View {
    if assetContext != nil {
      assetPropertyBody
    } else {
      enginePropertyBody
    }
  }

  private var enginePropertyBody: some View {
    let currentValue = localValue ?? binding.wrappedValue
    let text = displayText(for: currentValue)
    return HStack(spacing: readoutSpacing) {
      slider
        .modifier(CenteredTrackFill(
          fraction: Double((currentValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)),
          isActive: isCenteredRange && !Self.hasNativeNeutralValue,
        ))
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(spokenText(for: currentValue)))
        .accessibilityAdjustableAction { direction in
          // `mapping(…)`, so the adjustment lands in `bounds` space.
          adjustForAccessibility(direction, value: mapping(binding, bounds))
          localValue = nil
        }
        .onAppear { localValue = nil }
      if showsReadout {
        readout(text, widest: widestText(at: [bounds.lowerBound, bounds.upperBound].map(rawValue(atMapped:))))
      }
    }
    // A list row's separator starts at its first `Text`, which here is the
    // trailing readout, so the separator would only span the row's end.
    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
  }

  /// Reserves the width of `widest`, so the track rarely changes length.
  private func readout(_ text: String, widest: String) -> some View {
    ZStack(alignment: .trailing) {
      Text(widest).hidden()
      Text(text)
    }
    .font(.body.monospacedDigit())
    .foregroundStyle(.secondary)
    .frame(minWidth: 40, alignment: .trailing)
  }

  private func widestText(at values: [T]) -> String {
    values.map(displayText(for:)).max { $0.count < $1.count } ?? ""
  }

  /// The stored value at a point of ``bounds``. They differ under a non-linear `mapping`.
  private func rawValue(atMapped mappedValue: T) -> T {
    var raw = mappedValue
    mapping(Binding(get: { raw }, set: { raw = $0 }), bounds).wrappedValue = mappedValue
    return raw
  }

  /// A percentage range centred on zero, whose fill starts at zero. Wider ranges
  /// are excluded: on stroke width's −3…3 log scale, zero is 1 pt, not neutral.
  private var isCenteredRange: Bool {
    PercentageSliderHelper.isPercentageSlider(min: bounds.lowerBound, max: bounds.upperBound)
      && bounds.lowerBound < 0 && bounds.lowerBound == -bounds.upperBound
  }

  /// Detents need ``detentBinding`` to intercept and override the raw drag
  /// value, so they get their own slider.
  @ViewBuilder private var slider: some View {
    if isContinuous {
      Slider(value: mapping(sliderBinding, bounds), in: bounds, onEditingChanged: handleEditingChanged)
    } else if detents.isEmpty {
      steppedSlider(value: mapping(sliderBinding, bounds), onEditingChanged: handleEditingChanged)
    } else {
      detentSlider
    }
  }

  private static var hasNativeNeutralValue: Bool {
    if #available(iOS 26.0, *) {
      true
    } else {
      false
    }
  }

  /// On iOS 26 a centred range fills from zero natively; ``CenteredTrackFill`` draws it before.
  @ViewBuilder
  private func steppedSlider(value: Binding<T>, onEditingChanged: @escaping (Bool) -> Void) -> some View {
    if #available(iOS 26.0, *), isCenteredRange {
      // `step` with `neutralValue` draws a tick per step, so this rounds itself.
      let stepped = Binding<T>(
        get: { value.wrappedValue },
        set: { newValue in
          let snapped = NumberStepperMath.snapped(newValue, step: resolvedStep, origin: bounds.lowerBound)
          value.wrappedValue = NumberStepperMath.clamped(snapped, to: bounds)
        },
      )
      Slider(
        value: stepped, in: bounds, neutralValue: (bounds.lowerBound + bounds.upperBound) / 2,
        label: { EmptyView() }, onEditingChanged: onEditingChanged,
      )
    } else {
      Slider(value: value, in: bounds, step: T.Stride(resolvedStep), onEditingChanged: onEditingChanged)
    }
  }

  private func handleEditingChanged(_ started: Bool) {
    if !started {
      localValue = nil
      interactor.addUndoStep()
    }
  }

  /// Measures the track width for ``pointsPerValue``.
  private var detentSlider: some View {
    steppedSlider(value: mapping(detentBinding, bounds), onEditingChanged: handleDetentEditingChanged)
      .background(
        GeometryReader { proxy in
          Color.clear.preference(key: SliderWidthPreferenceKey.self, value: proxy.size.width)
        },
      )
      .onPreferenceChange(SliderWidthPreferenceKey.self) { sliderWidth = $0 }
  }

  /// Prepares the capture haptic, which fires only on capture, otherwise a
  /// 100-step slider buzzes continuously.
  private func handleDetentEditingChanged(_ started: Bool) {
    // Reset on both edges: a gesture the system cancels may never deliver
    // the release.
    detentState = .disarmed
    if started {
      let generator = UIImpactFeedbackGenerator(style: .light)
      generator.prepare()
      impactGenerator = generator
    } else {
      localValue = nil
      impactGenerator = nil
      interactor.addUndoStep()
    }
  }

  private var assetPropertyBody: some View {
    let text = displayText(for: assetValue)
    return VStack {
      HStack(spacing: readoutSpacing) {
        assetSlider
          .accessibilityLabel(Text(title))
          .accessibilityValue(Text(spokenText(for: assetValue)))
          .accessibilityAdjustableAction { direction in
            // `assetSlider` has no `mapping(…)`, so `assetValue` is in `bounds` space.
            adjustForAccessibility(direction, value: $assetValue)
          }
        readout(text, widest: widestText(at: [bounds.lowerBound, bounds.upperBound]))
      }
      .onChange(of: assetValue) { newValue in
        applyAssetProperty(value: newValue)
      }
    }
  }

  private var assetSlider: some View {
    Slider(value: $assetValue, in: bounds, step: T.Stride(resolvedStep)) { started in
      if !started {
        interactor.addUndoStep()
      }
    }
  }

  // MARK: - Asset Property Application

  private func applyAssetProperty(value: T) {
    guard let engine = interactor.engine,
          let assetContext,
          let buildUpdatedProperty,
          let updatedProperty = buildUpdatedProperty(assetContext.assetProperty, value) else { return }
    Task {
      try? await engine.asset.applyAssetSourceProperty(
        sourceID: assetContext.sourceID,
        assetResult: assetContext.assetResult,
        property: updatedProperty,
      )
    }
  }
}

/// Before iOS 26, draws a centred slider's fill from the middle to the thumb,
/// which `Slider` cannot. The native fill takes the track colour. The overlay
/// lies above the opaque 28 pt thumb, so it leaves out the thumb's footprint.
private struct CenteredTrackFill: ViewModifier {
  /// The value's position in the range, `0...1`.
  let fraction: Double
  let isActive: Bool

  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.layoutDirection) private var layoutDirection

  private let track: CGFloat = 4
  private let thumb: CGFloat = 28

  func body(content: Content) -> some View {
    if isActive {
      content
        .tint(Color(.systemFill))
        .overlay {
          GeometryReader { proxy in
            fill(in: proxy.size)
          }
          // The slider mirrors in right-to-left layouts; `fill` mirrors the
          // fraction itself, so it must lay out left to right.
          .environment(\.layoutDirection, .leftToRight)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
        }
    } else {
      content
    }
  }

  private func fill(in size: CGSize) -> some View {
    let center = size.width / 2
    let position = layoutDirection == .rightToLeft ? 1 - fraction : fraction
    let thumbX = thumb / 2 + CGFloat(position) * (size.width - thumb)
    let thumbGap = thumb / 2 + 1
    return ZStack(alignment: .topLeading) {
      Capsule()
        .fill(isEnabled ? Color.accentColor : Color(.tertiaryLabel))
        .frame(width: abs(thumbX - center), height: track)
        .offset(x: min(thumbX, center), y: (size.height - track) / 2)
      Capsule()
        .fill(Color(.tertiaryLabel))
        .frame(width: 2, height: track * 2)
        .offset(x: center - 1, y: (size.height - track * 2) / 2)
    }
    .frame(width: size.width, height: size.height, alignment: .topLeading)
    .mask {
      HStack(spacing: 0) {
        Color.black.frame(width: max(0, thumbX - thumbGap))
        Color.clear.frame(width: thumbGap * 2)
        Color.black
      }
    }
  }
}

private struct SliderWidthPreferenceKey: PreferenceKey {
  static let defaultValue: CGFloat? = nil
  static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    value = value ?? nextValue()
  }
}

// MARK: - Helpers

struct AssetClosures<T> {
  let extractValue: (AssetProperty) -> T?
  let buildUpdatedProperty: (AssetProperty, T) -> AssetProperty?
}

private extension PropertySlider {
  /// Returns a step value for the Slider when the asset property requires discrete snapping (e.g. int properties).
  static func extractStep(from assetProperty: AssetProperty) -> T? {
    switch assetProperty {
    case let .float(_, _, _, _, _, step) where step >= 1:
      T(step)
    case .int:
      T(exactly: 1)
    default:
      nil
    }
  }

  /// Builds extract/build closures by inspecting the `AssetProperty` case at runtime.
  static func assetClosures(for assetProperty: AssetProperty) -> AssetClosures<T> {
    switch assetProperty {
    case .float: floatClosures()
    case .double: doubleClosures()
    case .int: intClosures()
    default: AssetClosures(
        extractValue: { _ in nil },
        buildUpdatedProperty: { _, _ in nil },
      )
    }
  }

  private static func floatClosures() -> AssetClosures<T> {
    AssetClosures(
      extractValue: { prop in
        if case let .float(_, value, _, _, _, _) = prop {
          return value as? T
        }
        return nil
      },
      buildUpdatedProperty: { prop, value in
        if case let .float(property, _, defaultValue, min, max, step) = prop,
           let floatValue = value as? Float {
          return .float(
            property: property, value: floatValue, defaultValue: defaultValue,
            min: min, max: max, step: step,
          )
        }
        return nil
      },
    )
  }

  private static func doubleClosures() -> AssetClosures<T> {
    AssetClosures(
      extractValue: { prop in
        if case let .double(_, value, _, _, _, _) = prop {
          return value as? T
        }
        return nil
      },
      buildUpdatedProperty: { prop, value in
        if case let .double(property, _, defaultValue, min, max, step) = prop,
           let doubleValue = value as? Double {
          return .double(
            property: property, value: doubleValue, defaultValue: defaultValue,
            min: min, max: max, step: step,
          )
        }
        return nil
      },
    )
  }

  private static func intClosures() -> AssetClosures<T> {
    AssetClosures(
      extractValue: { prop in
        if case let .int(_, value, _, _, _, _) = prop {
          return T(exactly: value) ?? T(value)
        }
        return nil
      },
      buildUpdatedProperty: { prop, value in
        if case let .int(property, _, defaultValue, min, max, step) = prop {
          return .int(
            property: property, value: Int32(value), defaultValue: defaultValue,
            min: min, max: max, step: step,
          )
        }
        return nil
      },
    )
  }
}
