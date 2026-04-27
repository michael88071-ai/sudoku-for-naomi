import SwiftUI

/// Bottom sheet that shows the latest hint: the technique name, an embedded
/// mini-board with the hint cell highlighted, and a written explanation.
struct HintInfoPanelView: View {
    let hint: GameViewModel.HintContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceSettings.self) private var appearance

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    CandidateBoardView(
                        grid: hint.grid,
                        givens: hint.givens,
                        candidates: hint.candidates,
                        step: hint.step
                    )
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(appearance.backgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )

                    explanation
                    actionSummary
                }
                .padding(16)
            }
            .background(appearance.backgroundColor.ignoresSafeArea())
            .navigationTitle("Hint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
            Text(hint.step.technique.displayName)
                .font(.headline)
            Spacer()
            if !hint.step.units.isEmpty {
                Text(hint.step.units.map { $0.label }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Why")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(.init(hint.step.explanation))
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var actionSummary: some View {
        let placements = hint.step.actions.compactMap { action -> String? in
            if case let .place(r, c, d) = action { return "Place \(d) at (\(r + 1),\(c + 1))" }
            return nil
        }
        let elims = hint.step.actions.compactMap { action -> String? in
            if case let .eliminate(r, c, d) = action { return "Erase \(d) from (\(r + 1),\(c + 1))" }
            return nil
        }
        if !placements.isEmpty || !elims.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("What to do")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(placements, id: \.self) {
                    Text("· " + $0).font(.callout).foregroundStyle(.green)
                }
                if elims.count <= 6 {
                    ForEach(elims, id: \.self) {
                        Text("· " + $0).font(.callout).foregroundStyle(.red)
                    }
                } else {
                    Text("· Erase candidate from \(elims.count) cells")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
