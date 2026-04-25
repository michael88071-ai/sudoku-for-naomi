import SwiftUI

struct GameOverView: View {
    let result: GameView.EndResult
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 16)

            Image(systemName: result.status.systemImageName)
                .font(.system(size: 72))
                .foregroundStyle(statusColor)

            Text(headline)
                .font(.largeTitle.bold())

            VStack(spacing: 0) {
                statRow(label: "Difficulty", value: result.difficulty.displayName)
                Divider().padding(.horizontal)
                statRow(label: "Time", value: formatTime(result.elapsedSeconds))
                Divider().padding(.horizontal)
                statRow(label: "Mistakes", value: "\(result.mistakeCount)")
            }
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 32)

            Spacer()

            Button {
                dismiss()
                onDone()
            } label: {
                Text("Back to Home")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium, .large])
    }

    private var statusColor: Color {
        switch result.status {
        case .won: return .green
        case .quit: return .gray
        case .failed: return .orange
        }
    }

    private var headline: String {
        switch result.status {
        case .won: return "Solved!"
        case .quit: return "Game Quit"
        case .failed: return "Marked Failed"
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.body.weight(.medium).monospacedDigit())
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
