@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct CropOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  @State var minScaleRatio: Float = 1
  @State var isStraighteningOrRotating = false

  @ViewBuilder var cropOptions: some View {
    let cropScaleRatio: Binding<Float> = interactor.bind(id, property: .key(.cropScaleRatio), default: 1)
    let completion: Interactor.PropertyCompletion = { engine, blocks, didChange in
      if didChange {
        try blocks.forEach {
          isStraighteningOrRotating = true
          let oldCropScaleRatio = try engine.block.getCropScaleRatio($0)
          let contentFillMode = try engine.block.getContentFillMode($0)
          if contentFillMode != .contain {
            try engine.block.adjustCropToFillFrame($0, minScaleRatio: minScaleRatio)
          }
          let newCropScaleRatio = try engine.block.getCropScaleRatio($0)
          if oldCropScaleRatio == newCropScaleRatio {
            isStraighteningOrRotating = false
          }
        }
      }
      return didChange
    }
    let cropRotationRadians: Binding<Float> = interactor.bind(id, property: .key(.cropRotation),
                                                              default: 0, completion: completion)
    let cropRotationDegrees = Binding {
      cropRotationRadians.wrappedValue.toDegrees
    } set: { value in
      cropRotationRadians.wrappedValue = value.toRadians
    }
    let straightenDegrees = Binding {
      cropRotationDegrees.wrappedValue.decomposedDegrees.straightenDegrees
    } set: { value in
      // Use +-44.999 as bound to guarantee that `decomposedDegrees` is stable and thus
      // `straightenDegrees` won't jump from -45 to +45 or vice versa for some 90 degree rotations.
      let value = abs(value) >= 45 ? (value.sign == .minus ? -44.999 : 44.999) : value
      cropRotationDegrees.wrappedValue = cropRotationDegrees.wrappedValue.decomposedDegrees.rotationDegrees + value
    }

    HStack(alignment: .bottom, spacing: 0) {
      Button {
        interactor.actionButtonTapped(for: .flipCrop)
      } label: {
        Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
          .font(.title3)
          .tint(.primary)
          .frame(width: 44, height: 44)
          .padding(.leading, 8)
      }
      .accessibilityLabel("Flip")
      VStack(alignment: .center, spacing: 1) {
        Text("Rotate")
          .font(.caption2)
        MeasurementScalePicker(value: straightenDegrees, unit: UnitAngle.degrees, in: -45 ... 45,
                               tickStep: 3, tickSpacing: 10) { started in
          if !started {
            interactor.addUndoStep()
          }
        }
        .accessibilityLabel("Straighten")
      }
      Button {
        cropRotationDegrees.wrappedValue = (cropRotationDegrees.wrappedValue - 90).normalizedDegrees
        interactor.addUndoStep()
      } label: {
        Image(systemName: "rotate.left")
          .font(.title3)
          .tint(.primary)
      }
      .buttonStyle(.option)
      .frame(width: 44, height: 44)
      .padding(.trailing, 8)
      .accessibilityLabel("Rotate")
    }
    .padding(.vertical, 8)
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 13))
    .padding(.horizontal, 16)
    .onAppear {
      minScaleRatio = cropScaleRatio.wrappedValue
    }
    .onChange(of: cropScaleRatio.wrappedValue) { newValue in
      guard !isStraighteningOrRotating else {
        isStraighteningOrRotating = false
        return
      }
      minScaleRatio = newValue
    }
  }

  var body: some View {
    VStack {
      if interactor.supportsCrop(id) {
        cropOptions
          .padding(.bottom, 8)
        TransformOptions(interactor: interactor, item: { asset in
          TransformItem(asset: asset)
        },
        sources: sources,
        mode: transformMode)
      }
    }
    .background(Color(.systemGroupedBackground))
  }

  private var sources: [AssetLoader.SourceData] {
    switch (isPage, interactor.behavior.unselectedPageCrop) {
    case (true, true):
      [.init(id: "ly.img.crop.presets"), .init(id: "ly.img.page.presets")]
    case (true, false):
      [.init(id: "ly.img.page.presets")]
    case (false, _):
      [.init(id: "ly.img.crop.presets")]
    }
  }

  private var transformMode: TransformMode {
    guard let id else { return .cropAndResize }
    if !isPage { return .crop }
    let hasImageFill = interactor.get(id, .fill, property: .key(.type)) == Interactor.FillType.image.rawValue
    return hasImageFill ? .cropAndResize : .resize
  }

  private var isPage: Bool {
    guard let id else { return true }
    let isPage = interactor.get(id, property: .key(.type)) == Interactor.BlockType.page.rawValue
    return isPage
  }
}

private extension BinaryFloatingPoint {
  func wrappedAround(maxValue: Self) -> Self {
    var wrappedValue = truncatingRemainder(dividingBy: maxValue)
    if wrappedValue < 0 {
      wrappedValue += maxValue
    }
    return wrappedValue
  }

  var toDegrees: Self { self * Self(180 / Double.pi) }
  var toRadians: Self { self * Self(Double.pi / 180) }
  var normalizedDegrees: Self { wrappedAround(maxValue: 360) }
  var normalizedRadians: Self { wrappedAround(maxValue: 2 * .pi) }

  typealias DecomposedDegrees = (rotationDegrees: Self, straightenDegrees: Self)

  /// `normalizedDegrees` = `rotationDegrees` + `straightenDegrees`
  var decomposedDegrees: DecomposedDegrees {
    let normalized = normalizedDegrees
    var rotationCounts = (normalized / 90).rounded(.towardZero)
    func decompose() -> DecomposedDegrees {
      let rotationDegrees = rotationCounts * 90
      return (rotationDegrees: rotationDegrees, straightenDegrees: normalized - rotationDegrees)
    }
    var result = decompose()
    if result.straightenDegrees > 45 {
      rotationCounts += 1
      result = decompose()
    }
    assert(normalized == result.rotationDegrees + result.straightenDegrees)
    assert((-45 ... 45).contains(result.straightenDegrees))
    return result
  }
}

struct CropOptions_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
