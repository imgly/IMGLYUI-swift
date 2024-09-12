import SwiftUI
@_spi(Internal) import IMGLYCoreUI

extension ImagePaint {
  static let transparentColorPattern = ImagePaint(
    image: Image("transparent_color_pattern", bundle: .module),
    scale: {
      // Fix for iOS 17.0..<17.2 when compiled with Xcode 15 (https://github.com/oliverfoggin/ImagePaintTest)
      if #available(iOS 17.0, *) {
        if #available(iOS 17.2, *) {
          1
        } else {
          0.125
        }
      } else {
        1
      }
    }()
  )
}

extension ShapeStyle where Self == ImagePaint {
  static var transparentColorPattern: Self { .transparentColorPattern }
}

struct FillColorImage: View {
  let isEnabled: Bool
  @Binding var colors: [CGColor]

  var body: some View {
    ZStack {
      Image(systemName: "circle")
        .foregroundColor(Color(uiColor: .separator))
        .scaleEffect(1.05)
      Image(systemName: "circle.fill")
        .foregroundStyle(.transparentColorPattern)
      if isEnabled {
        Image(systemName: "circle.fill")
          .foregroundStyle(.linearGradient(colors: colors.map { Color(cgColor: $0) }, startPoint: .leading,
                                           endPoint: .trailing))
      } else {
        Image(systemName: "circle.slash")
          .foregroundStyle(.black, .clear)
      }
    }
  }
}

extension FillColorImage {
  init(isEnabled: Bool, color: Binding<CGColor>) {
    let binding = Binding<[CGColor]>.init {
      [color.wrappedValue]
    } set: { value in
      if let new = value.first {
        color.wrappedValue = new
      }
    }

    self.isEnabled = isEnabled
    _colors = binding
  }
}

struct StrokeColorImage: View {
  let isEnabled: Bool
  @Binding var color: CGColor

  var body: some View {
    ZStack {
      Image(systemName: "circle")
        .foregroundColor(.secondary)
        .scaleEffect(1.05)
      Image("custom.circle.circle.fill", bundle: .module)
        .foregroundColor(.secondary)
        .scaleEffect(0.9)
      Image("custom.circle.circle.fill", bundle: .module)
        .foregroundStyle(.transparentColorPattern)
      if isEnabled {
        Image("custom.circle.circle.fill", bundle: .module)
          .foregroundStyle(Color(cgColor: color))
      } else {
        Image(systemName: "circle.slash")
          .foregroundStyle(.black, .clear)
      }
    }
  }
}

struct ColorImage_Previews: PreviewProvider {
  static func constant(_ color: Color) -> Binding<CGColor> {
    .constant(color.asCGColor)
  }

  @ViewBuilder static var colors: some View {
    VStack {
      HStack {
        FillColorImage(isEnabled: true, color: constant(.red))
        FillColorImage(isEnabled: true, color: constant(.red.opacity(0.5)))
        FillColorImage(isEnabled: false, color: constant(.red))
        FillColorImage(isEnabled: false, color: constant(.red.opacity(0.5)))
      }
      HStack {
        StrokeColorImage(isEnabled: true, color: constant(.red))
        StrokeColorImage(isEnabled: true, color: constant(.red.opacity(0.5)))
        StrokeColorImage(isEnabled: false, color: constant(.red))
        StrokeColorImage(isEnabled: false, color: constant(.red.opacity(0.5)))
      }
      ZStack {
        AdaptiveOverlay {
          FillColorImage(isEnabled: true, color: constant(.red))
        } overlay: {
          StrokeColorImage(isEnabled: false, color: constant(.red.opacity(0.5)))
        }
      }
    }
    .font(.title)
  }

  static var previews: some View {
    colors
    colors.imgly.nonDefaultPreviewSettings()
  }
}
