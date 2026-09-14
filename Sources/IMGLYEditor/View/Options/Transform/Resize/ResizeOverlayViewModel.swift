@_spi(Internal) import IMGLYEngine
import SwiftUI

extension ResizeOverlay {
  enum EditField {
    case width
    case height
  }

  @MainActor
  class ViewModel: ObservableObject {
    let interactor: Interactor

    @Published private(set) var aspect: CGFloat?
    @Published var dpi: CGFloat
    @Published var pixelScale: CGFloat
    @Published var designUnit: DesignUnit {
      didSet {
        designUnitChanged(from: oldValue, to: designUnit)
      }
    }

    @Published var width: CGFloat {
      didSet {
        widthChanged(width)
      }
    }

    @Published var height: CGFloat {
      didSet {
        heightChanged(height)
      }
    }

    private var editingField: EditField?

    let numberFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.locale = Locale.current
      formatter.numberStyle = .decimal
      formatter.minimumFractionDigits = 0
      formatter.maximumFractionDigits = 2
      formatter.usesGroupingSeparator = false
      return formatter
    }()

    let resolutionValues: [CGFloat] = [72, 150, 300, 600, 1200, 2400]
    let pixelScaleValues: [CGFloat] = [0.5, 1, 1.5, 2, 3, 4]

    init(interactor: Interactor, dimensions: PageDimensions) {
      self.interactor = interactor

      _dpi = .init(initialValue: dimensions.dpi)
      _pixelScale = .init(initialValue: dimensions.pixelScale)
      _designUnit = .init(initialValue: dimensions.designUnit)
      _width = .init(initialValue: dimensions.width)
      _height = .init(initialValue: dimensions.height)
    }

    // MARK: - Interaction

    func apply() {
      try? interactor.resizePages(
        width: width,
        height: height,
        designUnit: designUnit,
        dpi: dpi,
        pixelScale: pixelScale,
      )
    }

    func updateAspect() {
      if aspect != nil {
        aspect = nil
      } else {
        aspect = width / height
      }
    }

    func formatValue(_ value: CGFloat) -> String {
      numberFormatter.string(from: NSNumber(value: Double(value))) ?? ""
    }

    // MARK: - Private

    private func widthChanged(_ newValue: CGFloat) {
      if let aspect {
        guard editingField != .height else { return }
        editingField = .width
        let newHeight = newValue / aspect
        height = newHeight
      }
      editingField = nil
    }

    private func heightChanged(_ newValue: CGFloat) {
      if let aspect {
        guard editingField != .width else { return }
        editingField = .height
        let newWidth = aspect * newValue
        width = newWidth
      }
      editingField = nil
    }

    private func designUnitChanged(from oldValue: DesignUnit, to newValue: DesignUnit) {
      let newWidth = DesignUnit.convert(
        width,
        from: oldValue,
        to: newValue,
        dpi: dpi,
        pixelScale: pixelScale,
      )
      let newHeight = DesignUnit.convert(
        height,
        from: oldValue,
        to: newValue,
        dpi: dpi,
        pixelScale: pixelScale,
      )
      width = newWidth
      height = newHeight
    }
  }
}
