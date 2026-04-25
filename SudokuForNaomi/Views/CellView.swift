import SwiftUI

struct CellView: View {
    let viewModel: GameViewModel
    let row: Int
    let col: Int

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
                    .font(.system(size: 24, weight: isGiven ? .bold : .medium, design: .rounded))
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
            Color.accentColor.opacity(0.40)
        } else if isPeer {
            Color.accentColor.opacity(0.22)
        } else if inLine {
            Color.accentColor.opacity(0.08)
        } else {
            Color(.systemBackground)
        }
    }

    private func textColor(isGiven: Bool, isFlagged: Bool) -> Color {
        if isFlagged { return .red }
        if isGiven { return .primary }
        return Color.accentColor
    }
}
