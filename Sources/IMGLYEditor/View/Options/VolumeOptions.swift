import SwiftUI
@_spi(Internal) import IMGLYCore

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
      if Double(volume) != value {
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
      setter: volumeSetter
    )
    let mutedBinding = interactor.bind(
      id,
      property: .raw(""),
      default: false,
      getter: mutedGetter,
      setter: mutedSetter
    )

    List {
      VolumeSliderView(value: volumeBinding, isMuted: mutedBinding)
        .padding(.trailing)
    }
  }
}

struct VolumeSliderView: View {
  private let knobWidth: CGFloat = 20
  private let knobHeight: CGFloat = 20

  @Binding var value: Double // 0 to 1
  @Binding var isMuted: Bool

  @State private var isDragging = false

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
    }
  }

  private var muteButton: some View {
    Button {
      isMuted.toggle()
    } label: {
      Group {
        if isMuted {
          Image(systemName: "speaker.slash")
            .foregroundStyle(.primary, Color.red)
        } else {
          Image(systemName: "speaker.wave.3", variableValue: value)
            .foregroundStyle(.primary)
        }
      }
      .fontWeight(.medium)
      .frame(minWidth: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(isMuted ? "Unmute" : "Mute")
  }

  private var slider: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let position = max(-knobWidth / 2, value * width - knobWidth / 2)

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
              .frame(width: isMuted ? 0 : max(0, position))
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
          .offset(x: isMuted ? -knobWidth / 2 : position)
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { gesture in
            isDragging = true

            isMuted = false

            let rawValue = max(0, min(width, gesture.location.x))

            guard width > 0 else { return }

            let normalizedValue = rawValue / width

            value = normalizedValue
          }
          .onEnded { _ in
            isDragging = false
          }
      )
    }
    .animation(.easeInOut(duration: max(0.15 * value, 0.1)), value: isMuted)
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
