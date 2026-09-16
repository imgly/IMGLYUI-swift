@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

enum AnimationPropertyDefinitions {
  // MARK: - Label Lookup

  private static let propertyLabels: [String: LocalizedStringResource] = [
    "playback/duration": .imgly.localized("ly_img_editor_sheet_animations_label_duration"),
    "animationEasing": .imgly.localized("ly_img_editor_sheet_animations_label_easing"),
    "textWritingStyle": .imgly.localized("ly_img_editor_sheet_animations_label_writing_style"),
    "textAnimationWritingStyle": .imgly.localized("ly_img_editor_sheet_animations_label_writing_style"),
  ]

  private static let propertySuffixLabels: [String: LocalizedStringResource] = [
    "/direction": .imgly.localized("ly_img_editor_sheet_animations_label_direction"),
    "/fade": .imgly.localized("ly_img_editor_sheet_animations_label_fade"),
    "/intensity": .imgly.localized("ly_img_editor_sheet_animations_label_intensity"),
    "/distance": .imgly.localized("ly_img_editor_sheet_animations_label_distance"),
    "/scale": .imgly.localized("ly_img_editor_sheet_animations_label_scale"),
    "/scaleFactor": .imgly.localized("ly_img_editor_sheet_animations_label_scale_factor"),
    "/travelDistanceRatio": .imgly.localized("ly_img_editor_sheet_animations_label_distance"),
    "/zoomIntensity": .imgly.localized("ly_img_editor_sheet_animations_label_zoom_intensity"),
    "/writingStyle": .imgly.localized("ly_img_editor_sheet_animations_label_writing_style"),
    "/startScale": .imgly.localized("ly_img_editor_sheet_animations_label_start_scale"),
    "/endScale": .imgly.localized("ly_img_editor_sheet_animations_label_end_scale"),
    "/startDelay": .imgly.localized("ly_img_editor_sheet_animations_label_start_delay"),
    "/holdDuration": .imgly.localized("ly_img_editor_sheet_animations_label_hold_duration"),
    "/easingDuration": .imgly.localized("ly_img_editor_sheet_animations_label_easing_duration"),
  ]

  private static let transitionPropertyLabels: [String: LocalizedStringResource] = [
    "playback/duration": .imgly.localized("ly_img_editor_sheet_transition_label_duration"),
    "animationEasing": .imgly.localized("ly_img_editor_sheet_transition_label_easing"),
  ]

  private static let transitionPropertySuffixLabels: [String: LocalizedStringResource] = [
    "/direction": .imgly.localized("ly_img_editor_sheet_transition_label_direction"),
    "/corner": .imgly.localized("ly_img_editor_sheet_transition_label_corner"),
    "/sigma": .imgly.localized("ly_img_editor_sheet_transition_label_blur"),
    "/blur": .imgly.localized("ly_img_editor_sheet_transition_label_blur"),
    "/zoom": .imgly.localized("ly_img_editor_sheet_transition_label_zoom"),
    "/intensity": .imgly.localized("ly_img_editor_sheet_transition_label_intensity"),
    "/bandCount": .imgly.localized("ly_img_editor_sheet_transition_label_band_count"),
    "/color": .imgly.localized("ly_img_editor_sheet_transition_label_color"),
    "/morph": .imgly.localized("ly_img_editor_sheet_transition_label_morph"),
  ]

  // MARK: - Enum Option Labels

  private static let enumOptionLabels: [String: LocalizedStringResource] = [
    // Easing
    "Linear": .imgly.localized("ly_img_editor_sheet_animations_easing_option_linear"),
    "EaseInQuint": .imgly.localized("ly_img_editor_sheet_animations_easing_option_smooth_accelerate"),
    "EaseOutQuint": .imgly.localized("ly_img_editor_sheet_animations_easing_option_smooth_decelerate"),
    "EaseInOutQuint": .imgly.localized("ly_img_editor_sheet_animations_easing_option_smooth_natural"),
    "EaseInBack": .imgly.localized("ly_img_editor_sheet_animations_easing_option_bounce_away"),
    "EaseOutBack": .imgly.localized("ly_img_editor_sheet_animations_easing_option_bounce_in"),
    "EaseInOutBack": .imgly.localized("ly_img_editor_sheet_animations_easing_option_bounce_double"),
    "EaseInSpring": .imgly.localized("ly_img_editor_sheet_animations_easing_option_wiggle_away"),
    "EaseOutSpring": .imgly.localized("ly_img_editor_sheet_animations_easing_option_wiggle_in"),
    "EaseInOutSpring": .imgly.localized("ly_img_editor_sheet_animations_easing_option_wiggle_double"),
    // Directions
    "Up": .imgly.localized("ly_img_editor_sheet_animations_label_direction_up"),
    "Right": .imgly.localized("ly_img_editor_sheet_animations_label_direction_right"),
    "Down": .imgly.localized("ly_img_editor_sheet_animations_label_direction_down"),
    "Left": .imgly.localized("ly_img_editor_sheet_animations_label_direction_left"),
    "Clockwise": .imgly.localized("ly_img_editor_sheet_animations_label_direction_clockwise"),
    "CounterClockwise": .imgly
      .localized("ly_img_editor_sheet_animations_label_direction_counter_clockwise"),
    "Horizontal": .imgly.localized("ly_img_editor_sheet_animations_label_direction_horizontal"),
    "Vertical": .imgly.localized("ly_img_editor_sheet_animations_label_direction_vertical"),
    "All": .imgly.localized("ly_img_editor_sheet_animations_label_direction_all"),
    "TopLeft": .imgly.localized("ly_img_editor_sheet_animations_label_direction_top_left"),
    "TopRight": .imgly.localized("ly_img_editor_sheet_animations_label_direction_top_right"),
    "BottomLeft": .imgly.localized("ly_img_editor_sheet_animations_label_direction_bottom_left"),
    "BottomRight": .imgly.localized("ly_img_editor_sheet_animations_label_direction_bottom_right"),
    // Writing Style
    "Block": .imgly.localized("ly_img_editor_sheet_animations_writing_style_option_block"),
    "Line": .imgly.localized("ly_img_editor_sheet_animations_writing_style_option_line"),
    "Character": .imgly.localized("ly_img_editor_sheet_animations_writing_style_option_character"),
    "Word": .imgly.localized("ly_img_editor_sheet_animations_writing_style_option_word"),
  ]

  private static let transitionEnumOptionLabels: [String: LocalizedStringResource] = [
    // Easing — transitions use the same engine enum values and localized labels as animations.
    "Linear": .imgly.localized("ly_img_editor_sheet_animations_easing_option_linear"),
    "EaseInQuint": .imgly.localized("ly_img_editor_sheet_animations_easing_option_smooth_accelerate"),
    "EaseOutQuint": .imgly.localized("ly_img_editor_sheet_animations_easing_option_smooth_decelerate"),
    "EaseInOutQuint": .imgly.localized("ly_img_editor_sheet_animations_easing_option_smooth_natural"),
    "EaseInBack": .imgly.localized("ly_img_editor_sheet_animations_easing_option_bounce_away"),
    "EaseOutBack": .imgly.localized("ly_img_editor_sheet_animations_easing_option_bounce_in"),
    "EaseInOutBack": .imgly.localized("ly_img_editor_sheet_animations_easing_option_bounce_double"),
    "EaseInSpring": .imgly.localized("ly_img_editor_sheet_animations_easing_option_wiggle_away"),
    "EaseOutSpring": .imgly.localized("ly_img_editor_sheet_animations_easing_option_wiggle_in"),
    "EaseInOutSpring": .imgly.localized("ly_img_editor_sheet_animations_easing_option_wiggle_double"),
    // Transition-specific options.
    "Up": .imgly.localized("ly_img_editor_sheet_transition_direction_up"),
    "Right": .imgly.localized("ly_img_editor_sheet_transition_direction_right"),
    "Down": .imgly.localized("ly_img_editor_sheet_transition_direction_down"),
    "Left": .imgly.localized("ly_img_editor_sheet_transition_direction_left"),
    "Clockwise": .imgly.localized("ly_img_editor_sheet_transition_direction_clockwise"),
    "CounterClockwise": .imgly.localized("ly_img_editor_sheet_transition_direction_counter_clockwise"),
    "Horizontal": .imgly.localized("ly_img_editor_sheet_transition_direction_horizontal"),
    "Vertical": .imgly.localized("ly_img_editor_sheet_transition_direction_vertical"),
    "TopLeft": .imgly.localized("ly_img_editor_sheet_transition_corner_top_left"),
    "TopRight": .imgly.localized("ly_img_editor_sheet_transition_corner_top_right"),
    "BottomLeft": .imgly.localized("ly_img_editor_sheet_transition_corner_bottom_left"),
    "BottomRight": .imgly.localized("ly_img_editor_sheet_transition_corner_bottom_right"),
    "RaisedRamp": .imgly.localized("ly_img_editor_sheet_transition_direction_raised_ramp"),
    "LoweredRamp": .imgly.localized("ly_img_editor_sheet_transition_direction_lowered_ramp"),
  ]

  // MARK: - Float-to-String Mappings

  private static func radiansToDirectionString(_ radians: Float) -> String {
    let twoPi = Float.pi * 2
    var dir = radians.truncatingRemainder(dividingBy: twoPi)
    if dir < 0 {
      dir += twoPi
    }
    if dir <= 0.25 * .pi || dir > 1.75 * .pi {
      return "Right"
    }
    if dir <= 0.75 * .pi {
      return "Down"
    }
    if dir <= 1.25 * .pi {
      return "Left"
    }
    return "Up"
  }

  // MARK: - Refresh from Engine

  /// Reads the current engine value for the given asset property and returns
  /// an updated copy with `value` set to the engine's current state.
  @MainActor
  static func refreshedAssetProperty(
    _ assetProperty: AssetProperty,
    from engine: Engine,
    blockID: Interactor.BlockID,
  ) -> AssetProperty? {
    do {
      switch assetProperty {
      case let .float(property, _, defaultValue, min, max, step):
        let current = try engine.block.getFloat(blockID, property: property)
        return .float(property: property, value: current, defaultValue: defaultValue,
                      min: min, max: max, step: step)
      case let .double(property, _, defaultValue, min, max, step):
        let current = try engine.block.getDouble(blockID, property: property)
        return .double(property: property, value: current, defaultValue: defaultValue,
                       min: min, max: max, step: step)
      case let .boolean(property, _, defaultValue):
        let current = try engine.block.getBool(blockID, property: property)
        return .boolean(property: property, value: current, defaultValue: defaultValue)
      case let .color(property, _, defaultValue):
        let current: IMGLYEngine.Color = try engine.block.getColor(blockID, property: property)
        return .color(property: property, value: current, defaultValue: defaultValue)
      case let .enum(property, _, defaultValue, options):
        let current: String
        if let enumValue = try? engine.block.getEnum(blockID, property: property) {
          current = enumValue
        } else {
          // Float-backed enum (e.g. direction stored as radians).
          let radians = try engine.block.getFloat(blockID, property: property)
          current = Self.radiansToDirectionString(radians)
        }
        return .enum(property: property, value: current, defaultValue: defaultValue,
                     options: options)
      case let .int(property, _, defaultValue, min, max, step):
        let propertyType = try engine.block.getType(ofProperty: property)
        if propertyType == .int {
          let current = Int32(try engine.block.getInt(blockID, property: property))
          return .int(property: property, value: current, defaultValue: defaultValue,
                      min: min, max: max, step: step)
        } else {
          // Some int-declared properties are stored as float in the engine.
          // Convert to .float so that read/write paths use the correct type.
          let current = try engine.block.getFloat(blockID, property: property)
          return .float(property: property, value: current, defaultValue: Float(defaultValue),
                        min: Float(min), max: Float(max), step: Float(step))
        }
      default:
        return nil
      }
    } catch {
      return nil
    }
  }

  // MARK: - Build Properties from Asset Payload

  private static func label(for propertyKey: String, sourceID: String) -> LocalizedStringResource {
    if sourceID == "ly.img.transitions" {
      if let label = transitionPropertyLabels[propertyKey] {
        return label
      }
      for (suffix, label) in transitionPropertySuffixLabels where propertyKey.hasSuffix(suffix) {
        return label
      }
    }
    if let label = propertyLabels[propertyKey] {
      return label
    }
    for (suffix, label) in propertySuffixLabels where propertyKey.hasSuffix(suffix) {
      return label
    }
    return .init(stringLiteral: propertyKey)
  }

  static func properties(
    from assetProperties: [AssetProperty],
    sourceID: String,
    assetResult: AssetResult,
    animationBlockID: Interactor.BlockID,
  ) -> [EffectProperty] {
    assetProperties.compactMap { assetProperty in
      effectProperty(
        from: assetProperty,
        sourceID: sourceID,
        assetResult: assetResult,
        blockID: animationBlockID,
      )
    }
  }

  private static func effectProperty(
    from assetProperty: AssetProperty,
    sourceID: String,
    assetResult: AssetResult,
    blockID: Interactor.BlockID,
  ) -> EffectProperty? {
    let context = EffectProperty.AssetContext(
      sourceID: sourceID,
      assetResult: assetResult,
      assetProperty: assetProperty,
    )

    switch assetProperty {
    case let .float(property, _, defaultValue, min, max, _):
      return EffectProperty(
        label: label(for: property, sourceID: sourceID),
        value: .float(range: min ... max, defaultValue: defaultValue),
        property: .raw(property),
        id: blockID,
        assetContext: context,
      )
    case let .double(property, _, defaultValue, min, max, _):
      return EffectProperty(
        label: label(for: property, sourceID: sourceID),
        value: .double(range: min ... max, defaultValue: defaultValue),
        property: .raw(property),
        id: blockID,
        assetContext: context,
      )
    case let .boolean(property, _, defaultValue):
      return EffectProperty(
        label: label(for: property, sourceID: sourceID),
        value: .boolean(defaultValue: defaultValue),
        property: .raw(property),
        id: blockID,
        assetContext: context,
      )
    case let .color(property, _, defaultValue):
      return EffectProperty(
        label: label(for: property, sourceID: sourceID),
        value: .color(supportsOpacity: true, defaultValue: defaultValue.cgColor),
        property: .raw(property),
        id: blockID,
        assetContext: context,
      )
    case let .enum(property, _, defaultValue, options):
      let optionLabels = sourceID == "ly.img.transitions" ? transitionEnumOptionLabels : enumOptionLabels
      let enumOptions = options.map { option in
        EffectProperty.EnumOption(
          id: option,
          label: optionLabels[option] ?? .init(stringLiteral: option),
        )
      }
      return EffectProperty(
        label: label(for: property, sourceID: sourceID),
        value: .enum(options: enumOptions, defaultValue: defaultValue),
        property: .raw(property),
        id: blockID,
        assetContext: context,
      )
    case let .int(property, _, defaultValue, min, max, _):
      return EffectProperty(
        label: label(for: property, sourceID: sourceID),
        value: .float(range: Float(min) ... Float(max), defaultValue: Float(defaultValue)),
        property: .raw(property),
        id: blockID,
        assetContext: context,
      )
    default:
      return nil
    }
  }
}
