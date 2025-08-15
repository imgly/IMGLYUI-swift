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
    @Published var designUnit: Interactor.DesignUnit {
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
        pixelScale: pixelScale
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

    private func convertUnit(
      from: Interactor.DesignUnit,
      to: Interactor.DesignUnit,
      with dpi: CGFloat,
      and pixelScale: CGFloat,
      value: CGFloat
    ) -> CGFloat {
      let mm_per_in = 25.4

      let valueInInches: CGFloat = switch from {
      case .in:
        value
      case .mm:
        value / mm_per_in
      case .px:
        value / (dpi * pixelScale)
      default: value
      }

      let convertedValue: CGFloat = switch to {
      case .in:
        valueInInches
      case .mm:
        valueInInches * mm_per_in
      case .px:
        valueInInches * dpi * pixelScale
      default: value
      }

      return convertedValue
    }

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

    private func designUnitChanged(from oldValue: Interactor.DesignUnit, to newValue: Interactor.DesignUnit) {
      let newWidth = convertUnit(from: oldValue, to: newValue, with: dpi, and: pixelScale, value: width)
      let newHeight = convertUnit(from: oldValue, to: newValue, with: dpi, and: pixelScale, value: height)
      width = newWidth
      height = newHeight
    }
  }
}
