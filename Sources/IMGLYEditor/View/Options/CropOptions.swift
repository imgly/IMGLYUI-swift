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
          try engine.block.adjustCropToFillFrame($0, minScaleRatio: minScaleRatio)
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

    Section("Straighten") {
      MeasurementScalePicker(value: straightenDegrees, unit: UnitAngle.degrees, in: -45 ... 45,
                             tickStep: 3, tickSpacing: 10) { started in
        if !started {
          interactor.addUndoStep()
        }
      }
      .accessibilityLabel("Straighten")
    }
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

    Section {
      EmptyView()
    } header: {
      HStack(spacing: 8) {
        ActionButton(.resetCrop)
          .disabled(!interactor.canResetCrop(id))
        Button {
          cropRotationDegrees.wrappedValue = (cropRotationDegrees.wrappedValue - 90).normalizedDegrees
          interactor.addUndoStep()
        } label: {
          Label("Rotate", systemImage: "rotate.left")
        }
        ActionButton(.flipCrop)
      }
      .tint(.primary)
      .buttonStyle(.option)
      .labelStyle(.tile(orientation: .vertical))
    }
    .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
    .textCase(.none)
  }

  var body: some View {
    List {
      if interactor.supportsCrop(id) {
        cropOptions
      }
    }
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
