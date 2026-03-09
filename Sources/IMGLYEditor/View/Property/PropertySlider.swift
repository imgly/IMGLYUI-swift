@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

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

  private let extractValue: ((AssetProperty) -> T?)?
  private let extractStepDigits: ((AssetProperty) -> Int?)?
  private let buildUpdatedProperty: ((AssetProperty, T) -> AssetProperty?)?
  private let assetStep: T?

  typealias Mapping = (_ value: Binding<T>, _ bounds: ClosedRange<T>) -> Binding<T>

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @State private var localValue: T?
  @State private var assetValue: T

  // MARK: - Engine Property Initializer

  init(_ title: LocalizedStringResource, in bounds: ClosedRange<T>, property: Property,
       mapping: @escaping Mapping = { value, _ in value },
       setter: @escaping Interactor.PropertySetter<T> = Interactor.Setter.set(),
       getter: @escaping Interactor.PropertyGetter<T> = Interactor.Getter.get(),
       propertyBlock: PropertyBlock? = nil,
       selection: Interactor.BlockID? = nil,
       defaultValue: T? = nil,
       assetContext: EffectProperty.AssetContext? = nil) {
    self.title = title
    self.bounds = bounds
    self.property = property
    self.mapping = mapping
    self.setter = setter
    self.getter = getter
    self.propertyBlock = propertyBlock
    self.selection = selection
    self.defaultValue = defaultValue
    self.assetContext = assetContext

    if let assetContext {
      let closures = Self.assetClosures(for: assetContext.assetProperty)
      extractValue = closures.extractValue
      extractStepDigits = closures.extractStepDigits
      buildUpdatedProperty = closures.buildUpdatedProperty
      let initialValue = closures.extractValue(assetContext.assetProperty) ?? defaultValue ?? bounds.lowerBound
      _assetValue = State(initialValue: initialValue)
      assetStep = Self.extractStep(from: assetContext.assetProperty)
    } else {
      extractValue = nil
      extractStepDigits = nil
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

  // MARK: - Asset Property Formatting

  private static var maxFractionDigits: Int { 2 }

  private var formattedValue: String? {
    guard let assetContext, let extractStepDigits else { return nil }
    let stepDigits = extractStepDigits(assetContext.assetProperty) ?? Self.maxFractionDigits
    let decimals = min(Self.maxFractionDigits, stepDigits)
    return String(format: "%.\(decimals)f", Double(assetValue))
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
    Slider(value: mapping(sliderBinding, bounds),
           in: bounds) { started in
      if !started {
        localValue = nil
        interactor.addUndoStep()
      }
    }
    .accessibilityLabel(Text(title))
    .onAppear { localValue = nil }
  }

  private var assetPropertyBody: some View {
    VStack {
      HStack {
        assetSlider
          .accessibilityLabel(Text(title))
        if let formattedValue {
          Text(formattedValue)
            .font(.body.monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(minWidth: 40, alignment: .trailing)
        }
      }
      .onChange(of: assetValue) { newValue in
        applyAssetProperty(value: newValue)
      }
    }
  }

  @ViewBuilder private var assetSlider: some View {
    if let assetStep {
      Slider(value: $assetValue, in: bounds, step: T.Stride(assetStep)) { started in
        if !started {
          interactor.addUndoStep()
        }
      }
    } else {
      Slider(value: $assetValue, in: bounds) { started in
        if !started {
          interactor.addUndoStep()
        }
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

// MARK: - Helpers

struct AssetClosures<T> {
  let extractValue: (AssetProperty) -> T?
  let extractStepDigits: (AssetProperty) -> Int?
  let buildUpdatedProperty: (AssetProperty, T) -> AssetProperty?
}

private extension PropertySlider {
  static func fractionDigits(of number: NSNumber) -> Int {
    let str = number.description
    guard let dotIndex = str.firstIndex(of: ".") else { return 0 }
    return str[str.index(after: dotIndex)...].count
  }

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
        extractStepDigits: { _ in nil },
        buildUpdatedProperty: { _, _ in nil },
      )
    }
  }

  private static func floatClosures() -> AssetClosures<T> {
    AssetClosures(
      extractValue: { prop in
        if case let .float(_, value, _, _, _, _) = prop { return value as? T }
        return nil
      },
      extractStepDigits: { prop in
        if case let .float(_, _, _, _, _, step) = prop {
          return fractionDigits(of: step as NSNumber)
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
        if case let .double(_, value, _, _, _, _) = prop { return value as? T }
        return nil
      },
      extractStepDigits: { prop in
        if case let .double(_, _, _, _, _, step) = prop {
          return fractionDigits(of: step as NSNumber)
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
        if case let .int(_, value, _, _, _, _) = prop { return T(exactly: value) ?? T(value) }
        return nil
      },
      extractStepDigits: { _ in
        0
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
