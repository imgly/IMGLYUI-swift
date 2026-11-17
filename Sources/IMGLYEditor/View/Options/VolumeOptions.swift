import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

struct VolumeOptions: View {
  @EnvironmentObject var interactor: Interactor
  @Environment(\.imglySelection) var id

  let volumeGetter: Interactor.PropertyGetter<Double> = { engine, id, _, _ in
    let type = try engine.block.getType(id)
    let isAudio = type == Interactor.BlockType.audio.rawValue
    let block = isAudio ? id : try engine.block.getFill(id)
    return Double(try engine.block.getVolume(block))
  }

  let volumeSetter: Interactor.PropertySetter<Double> = { engine, blocks, _, _, value, completion in
    var didChange = false
    try blocks.forEach { id in
      let type = try engine.block.getType(id)
      let isAudio = type == Interactor.BlockType.audio.rawValue
      let block = isAudio ? id : try engine.block.getFill(id)
      let volume = try engine.block.getVolume(block)
      // Also runs when only the mute state disagrees with the value, so this
      // setter alone decides mute: 0 mutes, anything above unmutes.
      if try Double(volume) != value || engine.block.isMuted(block) != (value == 0) {
        try engine.block.setVolume(block, volume: Float(value))
        if value == 0 {
          try engine.block.setMuted(block, muted: true)
        } else if value > 0 {
          try engine.block.setMuted(block, muted: false)
        }
        didChange = true
      }
    }
    return try (completion?(engine, blocks, didChange) ?? false) || didChange
  }

  let mutedGetter: Interactor.PropertyGetter<Bool> = { engine, id, _, _ in
    let type = try engine.block.getType(id)
    let isAudio = type == Interactor.BlockType.audio.rawValue
    let block = isAudio ? id : try engine.block.getFill(id)
    return try engine.block.isMuted(block)
  }

  let mutedSetter: Interactor.PropertySetter<Bool> = { engine, blocks, _, _, value, completion in
    var didChange = false
    try blocks.forEach { id in
      let type = try engine.block.getType(id)
      let isAudio = type == Interactor.BlockType.audio.rawValue
      let block = isAudio ? id : try engine.block.getFill(id)
      if try engine.block.isMuted(block) != value {
        let volume = try engine.block.getVolume(block)
        if value == false, volume == 0 {
          try engine.block.setVolume(block, volume: 0.2)
        }
        try engine.block.setMuted(block, muted: value)
        didChange = true
      }
    }
    return try (completion?(engine, blocks, didChange) ?? false) || didChange
  }

  var body: some View {
    let volumeBinding = interactor.bind(
      id,
      property: .raw(""),
      default: 0,
      getter: volumeGetter,
      setter: volumeSetter,
      completion: nil,
    )
    let mutedBinding = interactor.bind(
      id,
      property: .raw(""),
      default: false,
      getter: mutedGetter,
      setter: mutedSetter,
    )

    List {
      VolumeSliderView(value: volumeBinding, isMuted: mutedBinding) { isEditing in
        if !isEditing {
          interactor.addUndoStep()
        }
      }
      .padding(.trailing)
    }
  }
}

struct VolumeSliderView: View {
  private let knobWidth: CGFloat = 20
  private let knobHeight: CGFloat = 20

  @Binding var value: Double // 0 to 1
  @Binding var isMuted: Bool
  /// Reports `false` once per drag and per VoiceOver adjustment.
  var onEditingChanged: ((Bool) -> Void)?

  /// SwiftUI does not block a custom accessibility action on a disabled view,
  /// so the adjustable action guards on this.
  @Environment(\.isEnabled) private var isEnabled

  @State private var isDragging = false
  /// The finger's value during a drag. A clip's volume is on its fill, which
  /// sends no event for the selection, so the binding redraws only on release.
  @GestureState private var dragValue: Double?

  private var displayedValue: Double {
    dragValue ?? value
  }

  private var displaysMuted: Bool {
    isMuted && dragValue == nil
  }

  /// 1%, the fallback step of ``PropertySlider``, for drag and VoiceOver alike.
  private var step: Double {
    PercentageSliderHelper.stepFromMinMax(min: 0, max: 1)
  }

  /// `0%` while muted, like the wedge fill, whatever the stored ``value``.
  private var displayPercentage: Int {
    Int(((displaysMuted ? 0 : displayedValue) * 100).rounded())
  }

  /// Quantised to the step, so the stored value matches the rounded readout.
  private func steppedValue(atX x: CGFloat, width: CGFloat) -> Double {
    (max(0, min(width, x)) / width / step).rounded() * step
  }

  func shape(size: CGSize) -> Path {
    Path { path in
      path.move(to: CGPoint(x: 0, y: size.height / 24 * 12))
      path.addLine(to: CGPoint(x: size.width, y: size.height / 24 * 10))
      path.addLine(to: CGPoint(x: size.width, y: size.height / 24 * 14))
      path.addLine(to: CGPoint(x: 0, y: size.height / 24 * 12))
      path.closeSubpath()
    }
  }

  var body: some View {
    HStack {
      muteButton
      slider
      Text("\(displayPercentage)")
        .font(.body.monospacedDigit())
        .foregroundStyle(.secondary)
        .frame(minWidth: 40, alignment: .trailing)
        // Clears the knob, which overhangs the track at full volume.
        .padding(.leading, 8)
    }
  }

  private var muteButton: some View {
    Button {
      isMuted.toggle()
    } label: {
      Group {
        if displaysMuted {
          Image(systemName: "speaker.slash")
            .foregroundStyle(.primary, Color.red)
        } else {
          Image(systemName: "speaker.wave.3", variableValue: displayedValue)
            .foregroundStyle(.primary)
        }
      }
      .fontWeight(.medium)
      .frame(minWidth: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(.imgly.localized(
      isMuted ? "ly_img_editor_sheet_volume_button_unmute" : "ly_img_editor_sheet_volume_button_mute",
    )))
  }

  private var slider: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let position = max(-knobWidth / 2, displayedValue * width - knobWidth / 2)

      ZStack(alignment: .leading) {
        shape(size: geometry.size)
          .fill(.gray)
          .opacity(0.2)
          .overlay {
            shape(size: geometry.size)
              .stroke(.gray.opacity(0.4), lineWidth: 0.5)
          }

        shape(size: geometry.size)
          .fill(.blue)
          .opacity(0.3)
          .overlay {
            shape(size: geometry.size)
              .stroke(.blue, lineWidth: 1.5)
          }
          .mask(alignment: .leading) {
            Rectangle()
              .inset(by: -2)
              .frame(width: displaysMuted ? 0 : max(0, position))
          }

        RoundedRectangle(cornerRadius: knobWidth / 2)
          .fill(.white)
          .shadow(color: .black.opacity(0.1), radius: 5)
          .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 3)
          .frame(width: knobWidth)
          .frame(height: knobHeight)
          .overlay {
            if isDragging {
              RoundedRectangle(cornerRadius: knobWidth / 2)
                .fill(.blue.opacity(0.1))
            }
          }
          .overlay {
            RoundedRectangle(cornerRadius: knobWidth / 2)
              .inset(by: 0.25)
              .stroke(.gray.opacity(0.5), lineWidth: 0.5)
          }
          .offset(x: displaysMuted ? -knobWidth / 2 : position)
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { gesture in
            isDragging = true

            isMuted = false

            guard width > 0 else { return }
            value = steppedValue(atX: gesture.location.x, width: width)
          }
          .updating($dragValue) { gesture, dragValue, _ in
            guard width > 0 else { return }
            dragValue = steppedValue(atX: gesture.location.x, width: width)
          }
          .onEnded { _ in
            isDragging = false
            onEditingChanged?(false)
          },
      )
    }
    .animation(.easeInOut(duration: max(0.15 * value, 0.1)), value: isMuted)
    .accessibilityElement()
    .accessibilityLabel(Text(.imgly.localized("ly_img_editor_sheet_volume_title")))
    .accessibilityValue(Text("\(displayPercentage)%"))
    .accessibilityAdjustableAction { direction in
      guard isEnabled else { return }
      // Write only the value, so the volume setter decides mute. Setting
      // `isMuted` would turn a 0 into the mute setter's 20 % default.
      let current = isMuted ? 0 : value
      switch direction {
      case .increment:
        value = NumberStepperMath.stepped(current, direction: .up, step: step, bounds: 0 ... 1)
      case .decrement:
        value = NumberStepperMath.stepped(current, direction: .down, step: step, bounds: 0 ... 1)
      @unknown default:
        return
      }
      onEditingChanged?(false)
    }
  }
}

struct VolumeSliderView_Previews: PreviewProvider {
  static var previews: some View {
    VolumeSliderTestingView()
      .frame(height: 44)
      .padding(.horizontal, 100)
  }
}

private struct VolumeSliderTestingView: View {
  @State var sliderValue: Double = 1
  @State var isMuted: Bool = false

  var body: some View {
    VolumeSliderView(value: $sliderValue, isMuted: $isMuted)
      .onChange(of: sliderValue) { value in
        // swiftlint:disable redundant_discardable_let
        let _ = print(value)
      }
  }
}
