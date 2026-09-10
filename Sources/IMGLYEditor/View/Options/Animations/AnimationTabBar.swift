import SwiftUI

enum AnimationTab: Int, CaseIterable, Identifiable {
  case `in` = 0
  case loop = 1
  case out = 2

  var id: Int { rawValue }

  var label: LocalizedStringResource {
    switch self {
    case .in: .imgly.localized("ly_img_editor_sheet_animations_tab_in")
    case .loop: .imgly.localized("ly_img_editor_sheet_animations_tab_loop")
    case .out: .imgly.localized("ly_img_editor_sheet_animations_tab_out")
    }
  }

  var group: String {
    switch self {
    case .in: "in"
    case .loop: "loop"
    case .out: "out"
    }
  }
}

struct AnimationTabBar: View {
  @Binding var selectedTab: AnimationTab
  let hasAnimation: (AnimationTab) -> Bool

  var body: some View {
    VStack(spacing: 4) {
      Picker("", selection: $selectedTab) {
        ForEach(AnimationTab.allCases) { tab in
          Text(tab.label).tag(tab)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 16)

      HStack {
        ForEach(AnimationTab.allCases) { tab in
          Circle()
            .fill(hasAnimation(tab) ? Color.accentColor : .clear)
            .frame(width: 6, height: 6)
            .frame(maxWidth: .infinity)
        }
      }
      .padding(.horizontal, 16)
    }
    .padding(.bottom, 4)
    .background(Color(.systemGroupedBackground))
  }
}
