import SwiftUI

struct CellView: View {
    let viewModel: GameViewModel
    let row: Int
    let col: Int

    @Environment(AppearanceSettings.self) private var appearance

    var body: some View {
        let coord = SudokuBoard.Coord(row, col)
        let value = viewModel.board.value(row: row, col: col)
        let isGiven = viewModel.board.isGiven(row: row, col: col)
        let isSelected = viewModel.selectedCell == coord
        let isPeerHighlighted = viewModel.peerHighlightedCells.contains(coord)
        let isInRowOrCol = isInSameRowOrCol(coord: coord)
        let isConflict = viewModel.conflictingCells.contains(coord)
        let isWrong = viewModel.isMistake(row: row, col: col)

        ZStack {
            backgroundFor(
                isSelected: isSelected,
                isPeer: isPeerHighlighted,
                inLine: isInRowOrCol
            )

            if value > 0 {
                Text("\(value)")
                    .font(.system(size: appearance.cellFontSize, weight: isGiven ? .bold : .medium, design: .rounded))
                    .foregroundStyle(textColor(isGiven: isGiven, isFlagged: isWrong || isConflict))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectedCell = coord
        }
    }

    private func isInSameRowOrCol(coord: SudokuBoard.Coord) -> Bool {
        guard let sel = viewModel.selectedCell else { return false }
        if sel == coord { return false }
        return sel.row == coord.row || sel.col == coord.col
    }

    @ViewBuilder
    private func backgroundFor(isSelected: Bool, isPeer: Bool, inLine: Bool) -> some View {
        if isSelected {
            Color.accentColor.opacity(0.55)
        } else if isPeer {
            // Same-digit peers — strongest non-selection tint so they pop against white.
            Color.accentColor.opacity(0.34)
        } else if inLine {
            // Row/column of the selected cell. Bumped from 0.08 → 0.20 so it's
            // actually visible against a white board background.
            Color.accentColor.opacity(0.20)
        } else {
            appearance.backgroundColor
        }
    }

    private func textColor(isGiven: Bool, isFlagged: Bool) -> Color {
        if isFlagged { return .red }
        // Givens render in the user's chosen text color at full strength; player-entered
        // digits use the same hue at lower opacity so they stay visually distinct without
        // pulling in an unrelated accent color the user didn't pick.
        return isGiven ? appearance.textColor : appearance.textColor.opacity(0.7)
    }
}
