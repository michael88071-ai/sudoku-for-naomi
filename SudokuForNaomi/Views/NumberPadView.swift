import SwiftUI

struct NumberPadView: View {
    let viewModel: GameViewModel

    var body: some View {
        let isDisabled = viewModel.selectedCell == nil
            || (viewModel.selectedCell.map { viewModel.board.isGiven(row: $0.row, col: $0.col) } ?? true)
            || viewModel.phase != .playing

        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { n in
                    numberButton(n, disabled: isDisabled)
                }
            }
            HStack(spacing: 8) {
                ForEach(6...9, id: \.self) { n in
                    numberButton(n, disabled: isDisabled)
                }
                Button {
                    viewModel.clearSelected()
                } label: {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.accentColor.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.4 : 1)
            }
        }
    }

    private func numberButton(_ n: Int, disabled: Bool) -> some View {
        Button {
            viewModel.place(n)
        } label: {
            Text("\(n)")
                .font(.title.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.accentColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }
}
