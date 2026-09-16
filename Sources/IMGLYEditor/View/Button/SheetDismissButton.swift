import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct SheetDismissButton: View {
  @EnvironmentObject private var interactor: Interactor

  var body: some View {
    Button {
      interactor.sheetDismissButtonTapped()
    } label: {
      Label {
        Text(.imgly.localized("ly_img_editor_sheet_button_close"))
      } icon: {
        if #available(iOS 26.0, *), !usesLegacyDesign {
          // iOS 26 Liquid Glass: the toolbar supplies the circular background, so a plain chevron
          // avoids a doubled circle. System default size, primary tint.
          Image(systemName: "chevron.down")
            .foregroundColor(.primary)
        } else {
          // Legacy (pre-iOS 26): unchanged — filled-circle glyph at title2, secondary.
          Image(systemName: "chevron.down.circle.fill")
            .font(.title2)
            .foregroundColor(.secondary)
        }
      }
      .symbolRenderingMode(.hierarchical)
    }
  }
}

extension View {
  /// Styles a ``SheetDismissButton`` hosted in a titled-sheet toolbar.
  ///
  /// On iOS 26+ (Liquid Glass), keeping the system toolbar button style ensures the entire glass circle
  /// remains interactive. Applying `.buttonStyle(.borderless)` detaches the tap target from the glass,
  /// causing missed touches.
  ///
  /// Legacy/pre-iOS 26 retains `.borderless`. Note: Asset-library dismiss buttons should never use `.borderless`
  /// (see `Sheet.swift`).
  @ViewBuilder func sheetDismissButtonStyle() -> some View {
    if #available(iOS 26.0, *), !usesLegacyDesign {
      self
    } else {
      buttonStyle(.borderless)
    }
  }
}
