import SwiftUI
@_spi(Internal) import IMGLYCore

/// `[−] [ editable value · unit ] [+]`. Hold either button to repeat.
/// `bounds` can end at `.infinity` for a value that has no maximum.
///
/// Its sizes scale with Dynamic Type, so a caller caps it at
/// `.accessibility1`: beyond that the control is wider than a phone.
@MainActor
@_spi(Internal) public struct NumberStepperField<T: BinaryFloatingPoint>: View {
  @Binding var value: T
  let title: LocalizedStringResource
  let bounds: ClosedRange<T>
  let step: T
  var unit: String?
  var decimals: Int?
  /// For a caller that tracks its own enabled state. A `.disabled(…)` ancestor
  /// still wins, see ``isEffectivelyEnabled``.
  var isEnabled: Bool = true
  /// `false` shows a bare editable pill without the `[−] [+]` buttons.
  var showsButtons: Bool = true
  /// Reports the start and end of one press, hold, typed edit, or VoiceOver
  /// adjustment, never each repeated step, so a caller adds one undo step on `false`.
  var onEditingChanged: ((Bool) -> Void)?

  /// Read from the environment, so a call site that does not forward an
  /// ancestor's `.disabled(…)` still renders and behaves as disabled.
  @Environment(\.isEnabled) private var isEnvironmentEnabled

  @State private var editingText: String?
  /// `true` from focus until ``finishEditing()``, so the end of an edit is
  /// reported once whether focus loss or `onDisappear` comes first.
  @State private var isEditingSession = false
  @FocusState private var isFocused: Bool
  @AccessibilityFocusState private var isFieldAccessibilityFocused: Bool
  @AccessibilityFocusState private var isStepperAccessibilityFocused: Bool

  @ScaledMetric(relativeTo: .body) private var pillMinWidth: CGFloat = 83
  @ScaledMetric(relativeTo: .body) private var pillMaxWidth: CGFloat = 104
  @ScaledMetric(relativeTo: .body) private var buttonsWidth: CGFloat = 94
  @ScaledMetric(relativeTo: .body) private var dividerHeight: CGFloat = 18
  /// Tap height. The capsules draw inside it at the system stepper's ``capsuleHeight``.
  @ScaledMetric(relativeTo: .body) private var controlHeight: CGFloat = 44
  @ScaledMetric(relativeTo: .body) private var capsuleHeight: CGFloat = 32

  @_spi(Internal) public init(
    value: Binding<T>,
    title: LocalizedStringResource,
    bounds: ClosedRange<T>,
    step: T,
    unit: String? = nil,
    decimals: Int? = nil,
    isEnabled: Bool = true,
    showsButtons: Bool = true,
    onEditingChanged: ((Bool) -> Void)? = nil,
  ) {
    _value = value
    self.title = title
    self.bounds = bounds
    self.step = step
    self.unit = unit
    self.decimals = decimals
    self.isEnabled = isEnabled
    self.showsButtons = showsButtons
    self.onEditingChanged = onEditingChanged
  }

  private var resolvedDecimals: Int {
    decimals ?? NumberStepperMath.decimals(forStep: step)
  }

  /// Every enabled check reads this, never `isEnabled` alone, otherwise a
  /// `.disabled(…)` ancestor is ignored.
  private var isEffectivelyEnabled: Bool {
    isEnabled && isEnvironmentEnabled
  }

  /// Locale-aware, and drops trailing zeros: `24 pt`, `24,5 pt`.
  /// ``commit()`` accepts both separators.
  private var displayText: String {
    Double(value).formatted(.number.precision(.fractionLength(0 ... resolvedDecimals)).grouping(.never))
  }

  /// The widest value the field shows, such as `88.8` for `6...90` at 1 decimal, in the locale's format.
  /// A range with no maximum has no widest value, so the current value reserves the width, up to the 4 integer
  /// digits that the widest pill holds.
  private var widestText: String {
    let upperBound = if bounds.upperBound.isFinite {
      abs(Double(bounds.upperBound))
    } else {
      value.isFinite ? Swift.min(abs(Double(value)), 9999) : 0
    }
    let largest = Swift.max(abs(Double(bounds.lowerBound)), upperBound)
    let integerDigits = String(Int(largest)).count
    let eights = String(repeating: "8", count: integerDigits)
      + (resolvedDecimals > 0 ? "." + String(repeating: "8", count: resolvedDecimals) : "")
    let widest = (Double(eights) ?? largest) * (bounds.lowerBound < 0 ? -1 : 1)
    return widest.formatted(.number.precision(.fractionLength(resolvedDecimals)).grouping(.never))
  }

  /// The system stepper's shape: a capsule from iOS 26, a rounded rectangle before.
  private var controlShape: AnyShape {
    if #available(iOS 26.0, *) {
      AnyShape(Capsule())
    } else {
      AnyShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
  }

  private var atMin: Bool {
    value <= bounds.lowerBound
  }

  private var atMax: Bool {
    value >= bounds.upperBound
  }

  @_spi(Internal) public var body: some View {
    HStack(spacing: 6) {
      pill
      if showsButtons {
        HStack(spacing: 0) {
          button(systemName: "minus", direction: .down, isDisabled: atMin)
          Divider().frame(height: dividerHeight)
          button(systemName: "plus", direction: .up, isDisabled: atMax)
        }
        .frame(width: buttonsWidth, height: controlHeight)
        .background(controlShape.fill(Color(.tertiarySystemFill)).frame(height: capsuleHeight))
        // The adjustable action below replaces them for VoiceOver.
        .accessibilityHidden(true)
      }
    }
    // On the element VoiceOver reads, so a disabled stepper is announced as
    // dimmed.
    .disabled(!isEffectivelyEnabled)
    // One adjustable element, like SwiftUI's `Stepper`: VoiceOver never focuses
    // a `.contain` container. While typing, the text field is its own element.
    .accessibilityElement(children: isFocused ? .contain : .ignore)
    .accessibilityFocused($isStepperAccessibilityFocused)
    .accessibilityLabel(Text(title))
    .accessibilityValue(Text(unit.map { "\(displayText) \($0)" } ?? displayText))
    .accessibilityHint(Text(.imgly.localized("ly_img_editor_stepper_accessibility_hint_type_value")))
    .accessibilityAction {
      guard isEffectivelyEnabled else { return }
      isFocused = true
    }
    .accessibilityAdjustableAction { direction in
      guard isEffectivelyEnabled else { return }
      switch direction {
      case .increment:
        value = NumberStepperMath.stepped(value, direction: .up, step: step, bounds: bounds)
      case .decrement:
        value = NumberStepperMath.stepped(value, direction: .down, step: step, bounds: bounds)
      @unknown default:
        return
      }
      // A VoiceOver adjustment is one complete change, so report only `false`.
      onEditingChanged?(false)
    }
  }

  /// Value and unit share one colour, as in the system's value-and-stepper rows.
  private var valueColor: Color {
    isEffectivelyEnabled ? Color(.label) : Color(.secondaryLabel)
  }

  private var pill: some View {
    HStack(spacing: 4) {
      // A value off the step grid, such as 26.4 from a template, is wider than the narrowest pill, so the widest
      // value the range can show reserves the width, otherwise the field truncates it to `26…`.
      ZStack(alignment: .trailing) {
        Text(verbatim: widestText)
          // Fixed, otherwise it truncates like the field and reserves nothing.
          .fixedSize()
          .hidden()
          .accessibilityHidden(true)
        // Focus empties the field and shows the value as the prompt: the decimal
        // pad has no select-all, so typing replaces the value.
        TextField("", text: Binding(
          get: { editingText ?? displayText },
          set: { editingText = $0 },
        ), prompt: Text(displayText))
          // The decimal pad has no minus key, so a signed range gets the
          // punctuation keyboard instead.
          .keyboardType(bounds.lowerBound < 0 ? .numbersAndPunctuation : .decimalPad)
          .submitLabel(.done)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(valueColor)
          .focused($isFocused)
          .accessibilityFocused($isFieldAccessibilityFocused)
          .accessibilityLabel(Text(title))
          // Dropping focus is what commits: it runs the `onChange` below, so the
          // submit, Done, and tap-away paths stay one code path.
          .onSubmit { isFocused = false }
          .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
              // Every stepper in a sheet adds this group, so only the focused
              // field may fill it, otherwise the bar shows one Done per row.
              if isFocused {
                Spacer()
                Button {
                  isFocused = false
                } label: {
                  Text(.imgly.localized("ly_img_editor_common_button_done"))
                }
                .font(.body.weight(.semibold))
                // The toolbar inherits the sheet's button style, and a borderless one draws as a circle showing `Do…`.
                .buttonStyle(.automatic)
              }
            }
          }
      }
      if let unit {
        // The text field takes all free width, so a unit that may wrap breaks
        // into one letter per line.
        Text(verbatim: unit)
          .foregroundStyle(valueColor)
          .lineLimit(1)
          .fixedSize()
          .accessibilityHidden(true)
      }
    }
    .font(.body.monospacedDigit())
    .padding(.horizontal, 14)
    .frame(minWidth: pillMinWidth, maxWidth: pillMaxWidth, minHeight: controlHeight, maxHeight: controlHeight)
    .background(controlShape.fill(Color(.tertiarySystemFill)).frame(height: capsuleHeight))
    .onChange(of: isFocused) { focused in
      if focused {
        editingText = ""
        isEditingSession = true
        // The adjustable element is replaced by the text field, so move
        // VoiceOver onto it once the field exists as its own element.
        Task { @MainActor in isFieldAccessibilityFocused = true }
        onEditingChanged?(true)
      } else {
        finishEditing()
        // Otherwise VoiceOver lands anywhere once the text field disappears.
        Task { @MainActor in isStepperAccessibilityFocused = true }
      }
    }
    // A sheet closed mid-edit does not reliably drop focus first, and a row
    // scrolled out of a `List` must not keep a half-typed value.
    .onDisappear {
      finishEditing()
      isFocused = false
    }
  }

  /// Runs once per edit. The caller's `false` handler reads engine state, so
  /// the commit comes first.
  private func finishEditing() {
    guard isEditingSession else { return }
    isEditingSession = false
    commit()
    onEditingChanged?(false)
  }

  /// Rounds to ``resolvedDecimals``, so the value matches the pill. Does not
  /// snap to `step`, otherwise a field whose buttons move by 1 rounds `24.5` to `25`.
  /// Unparseable or non-finite text leaves `value` unchanged.
  private func commit() {
    defer { editingText = nil }
    guard let text = editingText,
          let parsed = Double(text.replacingOccurrences(of: ",", with: ".")),
          // `Double("nan")` parses, and `clamped` passes NaN through.
          parsed.isFinite else { return }
    let rounded = Double(String(format: "%.\(resolvedDecimals)f", parsed)) ?? parsed
    let committed = NumberStepperMath.clamped(T(rounded), to: bounds)
    // A long digit string overflows `T` to infinity, and a range with no maximum does not clamp it.
    guard committed.isFinite else { return }
    value = committed
  }

  private func button(systemName: String, direction: NumberStepperMath.Direction, isDisabled: Bool) -> some View {
    NumberStepperButton(
      systemName: systemName,
      isEnabled: isEffectivelyEnabled && !isDisabled,
      // Names the property, so VoiceOver says "Increase Stroke Width" rather
      // than a bare "Increase". Matches the Web editor's `input.stepper.*`.
      accessibilityLabel: {
        let property = String(localized: title)
        return systemName == "plus"
          ? String(localized: .imgly.localized("ly_img_editor_stepper_button_increase \(property)"))
          : String(localized: .imgly.localized("ly_img_editor_stepper_button_decrease \(property)"))
      }(),
      onTrigger: {
        // A press while typing ends the edit first, so the step starts from
        // the typed value and a later commit cannot overwrite the step.
        if isFocused {
          finishEditing()
          isFocused = false
        }
        // `false` at a bound stops the hold-to-repeat loop.
        let next = NumberStepperMath.stepped(value, direction: direction, step: step, bounds: bounds)
        guard next != value else { return false }
        value = next
        return true
      },
      onPressingChanged: onEditingChanged,
    )
  }
}

/// A `[−]`/`[+]` button that repeats while held. The repeat stops on release,
/// on disappear, at a bound, and when the button is disabled mid-hold.
@MainActor
private struct NumberStepperButton: View {
  let systemName: String
  let isEnabled: Bool
  let accessibilityLabel: String
  let onTrigger: () -> Bool
  /// Reports each press-down and release. A repeat that stops at a bound
  /// does not report a release, because the finger is still down.
  let onPressingChanged: ((Bool) -> Void)?

  @State private var isPressing = false
  @State private var repeatTask: Task<Void, Never>?
  @State private var didLongPress = false

  var body: some View {
    Button(action: handleTap) {
      Image(systemName: systemName)
        .font(.body)
        .foregroundStyle(isEnabled ? Color.primary : Color(.tertiaryLabel))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
    .accessibilityLabel(accessibilityLabel)
    .onLongPressGesture(minimumDuration: 0.5, pressing: handlePressing, perform: {})
    .onDisappear(perform: stopRepeating)
    .onChange(of: isEnabled) { enabled in
      // The repeat task captured this struct, so its `isEnabled` is frozen at
      // press time. `repeatTask` is `@State`, so cancelling here still reaches it.
      if !enabled {
        stopRepeating()
      }
    }
  }

  private func handleTap() {
    guard isEnabled, !didLongPress else { return }
    _ = onTrigger()
  }

  private func handlePressing(_ pressing: Bool) {
    isPressing = pressing
    onPressingChanged?(pressing)
    if pressing {
      startRepeating()
    } else {
      stopRepeating()
    }
  }

  private func startRepeating() {
    guard isEnabled else { return }
    stopRepeating()
    repeatTask = Task { @MainActor in
      try? await Task.sleep(nanoseconds: 400_000_000)
      guard !Task.isCancelled, isPressing, isEnabled else { return }
      didLongPress = true
      guard onTrigger() else { return }
      var repeats = 0
      while !Task.isCancelled, isPressing, isEnabled {
        try? await Task.sleep(nanoseconds: Self.repeatInterval(after: repeats))
        repeats += 1
        guard !Task.isCancelled, isPressing, isEnabled else { return }
        if !onTrigger() {
          stopRepeating()
          return
        }
      }
    }
  }

  /// Speeds up, but never jumps by more than one step: the grid starts at the
  /// lower bound, so a ×10 step would land font size on 16, 26, 36.
  private static func repeatInterval(after repeats: Int) -> UInt64 {
    switch repeats {
    case ..<10: 120_000_000
    case ..<40: 60_000_000
    default: 30_000_000
    }
  }

  private func stopRepeating() {
    repeatTask?.cancel()
    repeatTask = nil
    didLongPress = false
  }
}

struct NumberStepperField_Previews: PreviewProvider {
  static var previews: some View {
    NumberStepperFieldPreview()
      .padding()
      .previewLayout(.sizeThatFits)
  }
}

private struct NumberStepperFieldPreview: View {
  @State private var value: Double = 24

  var body: some View {
    NumberStepperField(
      value: $value,
      title: "Corner Radius",
      bounds: 6 ... 90,
      step: 1,
      unit: "pt",
    )
  }
}
