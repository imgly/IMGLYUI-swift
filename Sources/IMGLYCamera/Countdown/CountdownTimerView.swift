import SwiftUI

struct CountdownTimerView: View {
  @EnvironmentObject var camera: CameraModel

  @ObservedObject var countdownTimer: CountdownTimer

  var body: some View {
    let noAnimate = countdownTimer.remainingSeconds == countdownTimer.totalSeconds
    ZStack {
      Circle()
        .fill(countdownTimer.remainingSeconds > 0
          ? .black.opacity(0.64)
          : camera.configuration.recordingColor.opacity(0.64))
        .animation(noAnimate ? nil : .easeInOut(duration: 1), value: countdownTimer.status)
        .zIndex(1)
      Circle()
        .inset(by: 5)
        .trim(from: 1 - countdownTimer.remainingSeconds / countdownTimer.totalSeconds, to: 1)
        .rotation(.degrees(-90))
        .stroke(.white, lineWidth: 12)
        .opacity(countdownTimer.remainingSeconds > 0 ? 1 : 0)
        .animation(
          noAnimate ? nil : .imgly.slide,
          value: countdownTimer.remainingSeconds,
        )
        .zIndex(1)
      ZStack {
        if countdownTimer.status == .started {
          ZStack {
            // Alternate between two text fields to enable insertion/removal transitions.
            Group {
              if Int(countdownTimer.remainingSeconds) % 2 == 0 {
                Text(verbatim: "\(Int(countdownTimer.remainingSeconds))")
                  .id("CountdownTimerID1-\(countdownTimer.remainingSeconds)")

              } else {
                Text(verbatim: "\(Int(countdownTimer.remainingSeconds))")
                  .id("CountdownTimerID2-\(countdownTimer.remainingSeconds)")
              }
            }
            .frame(maxWidth: .infinity)
            .transition(.asymmetric(
              insertion: .offset(y: -70)
                .combined(with: .scale(scale: 0.7))
                .combined(with: .opacity),
              removal: .offset(y: 30)
                .combined(with: .scale(scale: 0))
                .combined(with: .opacity),
            ))
          }
          // Optical correction
          .offset(y: -3)
          .animation(
            .imgly.slide,
            value: countdownTimer.remainingSeconds,
          )
          .font(.system(size: 128))
          .tracking(0.8)
          .fontWeight(.semibold)
          .foregroundColor(.white)
          .transition(.scale.combined(with: .opacity))
        } else {
          if countdownTimer.status == .finished {
            Circle()
              .fill(.white)
              .frame(width: 100)
              .transition(.scale.combined(with: .opacity))
          } else {
            RoundedRectangle(cornerRadius: 16)
              .fill(.white)
              .frame(width: 100)
              .frame(height: 100)
              .transition(.scale.combined(with: .opacity))
          }
        }
      }
      .zIndex(2)
      .animation(noAnimate ? nil : .imgly.growShrinkQuick, value: countdownTimer.status)
    }
    .frame(width: 230, height: 230)
  }
}

struct CountdownTimerView_Previews: PreviewProvider {
  static let countdownTimer: CountdownTimer = {
    let countdownTimer = CountdownTimer()
    countdownTimer.start(seconds: 10) {
      print("done")
    }
    return countdownTimer
  }()

  static var previews: some View {
    CountdownTimerView(countdownTimer: countdownTimer)
      .environmentObject(CameraModel(.init(license: ""), onDismiss: .modern { _ in }))
  }
}
