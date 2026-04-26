import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \GameRecord.endedAt, order: .reverse) private var records: [GameRecord]
    @Environment(\.modelContext) private var modelContext
    @Environment(AppearanceSettings.self) private var appearance

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    "No games yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Finish a game to see it here.")
                )
            } else {
                List {
                    Section {
                        statsBlock
                    }
                    Section("Past Games") {
                        ForEach(records) { record in
                            recordRow(record)
                        }
                        .onDelete(perform: delete)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appearance.backgroundColor.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stats

    private var statsBlock: some View {
        let played = records.count
        let won = records.filter { $0.status == .won }.count
        let bestSeconds = records
            .filter { $0.status == .won }
            .map(\.elapsedSeconds)
            .min()

        return HStack(spacing: 16) {
            stat("Played", "\(played)")
            Divider()
            stat("Won", "\(won)")
            Divider()
            stat("Best", bestSeconds.map(formatTime) ?? "—")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Row

    private func recordRow(_ r: GameRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: r.status.systemImageName)
                .foregroundStyle(statusColor(r.status))
                .font(.title3)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(r.difficulty.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text("·").foregroundStyle(.tertiary)
                    Text(r.status.displayName)
                        .font(.subheadline)
                        .foregroundStyle(statusColor(r.status))
                }
                Text(r.endedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(r.elapsedSeconds))
                    .font(.subheadline.weight(.medium).monospacedDigit())
                if r.mistakeCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("\(r.mistakeCount)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func statusColor(_ s: GameStatus) -> Color {
        switch s {
        case .won: return .green
        case .quit: return .gray
        case .failed: return .orange
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(records[i])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: GameRecord.self, inMemory: true)
}
