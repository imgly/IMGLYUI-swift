import Foundation

enum ZoomEvent {
  case canvasGeometryChanged
  case pageChanged
  case sheetGeometryChanged
  case textCursorChanged(CGPoint?)
  case sheetClosed
  case pageSizeChanged
}
