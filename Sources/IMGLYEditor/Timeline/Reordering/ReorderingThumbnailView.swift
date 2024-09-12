@_spi(Internal) import IMGLYCore
import SwiftUI

/// Manages a thumbnail and its dragging and reordering logic.
struct ReorderingThumbnailView: View {
  enum DragState: Equatable {
    case inactive
    case pressing
    case dragging(translation: CGSize)

    var translation: CGSize {
      switch self {
      case .inactive, .pressing:
        .zero
      case let .dragging(translation):
        translation
      }
    }

    var isDragging: Bool {
      switch self {
      case .inactive, .pressing:
        false
      case .dragging:
        true
      }
    }
  }

  @EnvironmentObject var interactor: AnyTimelineInteractor
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  @GestureState private var dragState = DragState.inactive
  @State private var viewState = CGSize.zero

  let index: Int

  @ObservedObject var clip: Clip
  @ObservedObject var thumbnailsProvider: ThumbnailsImageProvider

  @Binding var clips: [Clip]
  @Binding var draggedClip: Clip?

  let thumbnailWidth: CGFloat
  let thumbnailHeight: CGFloat
  let thumbnailSpacing: CGFloat

  @ScaledMetric var cornerRadius = 8
  @ScaledMetric var labelPadding = 4

  @State private var isDragging = false
  @State private var xOffset: CGFloat = 0
  @State private var yOffset: CGFloat = 0
  @State private var dashPhase: CGFloat = 0

  @State private var indicatorOffset: CGFloat = 0

  @State private var isPressed = false

  init(index: Int, clip: Clip,
       clips: Binding<[Clip]>,
       draggedClip: Binding<Clip?>,
       thumbnailHeight: CGFloat,
       thumbnailSpacing: CGFloat,
       thumbnailsProvider: ThumbnailsImageProvider) {
    self.index = index
    self.clip = clip
    _clips = clips
    _draggedClip = draggedClip
    thumbnailWidth = round(thumbnailHeight / 16 * 9)
    self.thumbnailHeight = thumbnailHeight
    self.thumbnailSpacing = thumbnailSpacing
    self.thumbnailsProvider = thumbnailsProvider
  }

  var body: some View {
    GeometryReader { geometry in
      Button {} label: {
        ZStack {
          if isDragging {
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(style: SwiftUI.StrokeStyle(lineWidth: 1, dash: [2], dashPhase: dashPhase))
              .foregroundColor(configuration.timelineSnapIndicatorColor)
              .animation(Animation.linear.repeatForever(autoreverses: false).speed(0.3), value: dashPhase)
              .onAppear {
                dashPhase -= 4
              }

            if abs(indicatorOffset) > thumbnailWidth {
              RoundedRectangle(cornerRadius: 3)
                .fill(configuration.timelineSnapIndicatorColor)
                .frame(width: 3, height: thumbnailHeight * 2)
                .padding(.vertical, -thumbnailHeight * 0.5)
                .offset(x: indicatorOffset)
            }
          }

          Rectangle()
            .fill(.primary)
            .overlay {
              if let image = thumbnailsProvider.images.first {
                Image(uiImage: UIImage(cgImage: image ?? UIImage().cgImage!))
                  .resizable()
                  .aspectRatio(contentMode: .fill)
              }
            }
            .mask(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
              RoundedRectangle(cornerRadius: cornerRadius)
                .inset(by: 0.5)
                .stroke(.primary.opacity(0.2), lineWidth: 1)
            }
            .overlay(alignment: .bottomLeading) {
              HStack(spacing: 2) {
                HStack(spacing: 2) {
                  if let duration = clip.duration {
                    Text(duration.imgly.formattedDurationStringForClip())
                      .fixedSize()
                  }
                }
                .monospacedDigit()
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background {
                  RoundedRectangle(cornerRadius: max(0, cornerRadius - labelPadding))
                    .fill(.ultraThinMaterial)
                }
              }
              .padding(labelPadding)
              .font(.footnote)
            }
            .scaleEffect(isDragging || isPressed ? 1.3 : 1)
            .animation(.easeOut(duration: 0.7), value: isPressed)
            .offset(x: xOffset, y: yOffset)
            .onChange(of: xOffset) { newValue in
              let withSpacingWidth = thumbnailWidth + thumbnailSpacing
              var clampedXOffset = max(-Double(index) * geometry.size.width, newValue)
              clampedXOffset = min(Double(clips.count - index) * geometry.size.width, clampedXOffset)
              indicatorOffset = ceil(clampedXOffset / geometry.size.width) * withSpacingWidth - withSpacingWidth / 2
            }
            .onChange(of: indicatorOffset) { _ in
              if abs(xOffset) > thumbnailWidth / 2 {
                HapticsHelper.shared.timelineReorderSnap()
              }
            }
            .onTapGesture {
              // This comes before the long-press gesture to make scrolling the enclosing ScrollView work.
            }
            .gesture(
              LongPressGesture(minimumDuration: 0.2)
                .sequenced(before: DragGesture())
                .updating($dragState) { value, state, _ in
                  switch value {
                  case .first(true):
                    state = .pressing
                  case .second(true, let drag):
                    state = .dragging(translation: drag?.translation ?? .zero)
                  default:
                    state = .inactive
                  }
                }
                .onEnded { value in
                  withAnimation(Animation.interpolatingSpring(mass: 0.04,
                                                              stiffness: 10.0,
                                                              damping: 0.93,
                                                              initialVelocity: 8.0)) {
                    isDragging = false
                  }

                  guard case .second(true, let drag?) = value else { return }

                  viewState.width += drag.translation.width
                  viewState.height += drag.translation.height

                  withAnimation(Animation.interpolatingSpring(mass: 0.04,
                                                              stiffness: 10.0,
                                                              damping: 0.93,
                                                              initialVelocity: 8.0)) {
                    xOffset = 0
                    yOffset = 0

                    let indexOffset = Int(drag.translation.width / geometry.size.width)
                    let newIndex = max(0, min(clips.endIndex - 1, index + indexOffset))

                    if newIndex != index {
                      let clip = clips.remove(at: index)

                      // Optimistically change the order in the data source:
                      clips.insert(clip, at: newIndex)

                      // Then actually change it in the engine:
                      interactor.reorderBackgroundTrack(clip: clip, toIndex: newIndex)
                    }

                    HapticsHelper.shared.timelineReorderFinish()
                  }
                }
            )
            .onChange(of: dragState) { value in

              withAnimation(.easeInOut(duration: 0.03)) {
                if !isDragging {
                  draggedClip = clip
                  HapticsHelper.shared.timelineReorderStart()
                }

                xOffset = value.translation.width
                yOffset = rubberband(value.translation.height)
                isDragging = dragState.isDragging
              }
            }
        }
      }
      .buttonStyle(LongPressButtonStyle(isPressed: $isPressed))
    }
    .frame(width: thumbnailWidth, height: thumbnailHeight)
  }

  private func rubberband(_ points: CGFloat) -> CGFloat {
    guard points > 0 else { return 0 }
    let divisor = (points * 0.05) + 1.0
    let result = (1.0 - (1.0 / divisor)) * 40
    return result
  }
}

// This is a hack to detect the start of a long press gesture in a scroll view.
private struct LongPressButtonStyle: ButtonStyle, @unchecked Sendable {
  @Binding var isPressed: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .onChange(of: configuration.isPressed) { newValue in
        isPressed = newValue
      }
  }
}
