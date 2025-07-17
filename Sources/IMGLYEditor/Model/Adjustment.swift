import Foundation

enum Adjustment: String, RawRepresentable, CaseIterable {
  case brightness
  case saturation
  case contrast
  case gamma
  case clarity
  case exposure
  case shadows
  case highlights
  case blacks
  case whites
  case temperature
  case sharpness
}
