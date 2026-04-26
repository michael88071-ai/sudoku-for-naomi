import SwiftUI

/// One cell of the learning board. Renders either the placed digit, or a 3×3
/// pencil-mark grid of candidate digits with optional role-based highlighting.
struct CandidateCellView: View {
    let value: Int               // 0 = empty
    let isGiven: Bool
    let candidates: Set<Int>
    /// Role of this cell in the current step, if any.
    let role: HighlightedCell.Role?
    /// Specific candidate digits that should be visually emphasized inside the pencil grid.
    let emphasizedDigits: Set<Int>
    /// True when the highlight is calling out a candidate that's about to be eliminated (red).
    let isEliminationTarget: Bool
    /// True when the highlight is calling out a digit that's about to be placed (green).
    let isPlacement: Bool

    @Environment(AppearanceSettings.self) private var appearance

    var body: some View {
        ZStack {
            background

            if value > 0 {
                Text("\(value)")
                    .font(.system(size: max(appearance.cellFontSize - 2, 14), weight: isGiven ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isGiven ? appearance.textColor : appearance.textColor.opacity(0.7))
            } else {
                pencilGrid
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        switch role {
        case .target:
            (isEliminationTarget ? Color.red.opacity(0.18) : Color.green.opacity(0.22))
        case .subject:
            Color.orange.opacity(0.22)
        case .eliminator:
            Color.gray.opacity(0.16)
        case .unit:
            Color.accentColor.opacity(0.06)
        case .none:
            appearance.backgroundColor
        }
    }

    private var pencilGrid: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) / 3
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { c in
                            let d = r * 3 + c + 1
                            ZStack {
                                if candidates.contains(d) {
                                    Text("\(d)")
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundStyle(pencilColor(for: d))
                                }
                            }
                            .frame(width: side, height: side)
                        }
                    }
                }
            }
        }
    }

    private func pencilColor(for digit: Int) -> Color {
        if emphasizedDigits.contains(digit) {
            if isEliminationTarget { return .red }
            if isPlacement { return .green }
            return .orange
        }
        return appearance.textColor.opacity(0.55)
    }
}
