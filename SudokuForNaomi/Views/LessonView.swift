import SwiftUI

/// Walkthrough UI for a single lesson. The user sees the candidate board with
/// the current step's highlights, reads the explanation, and taps "Apply" to
/// advance.
struct LessonView: View {
    @State private var session: LearningSessionViewModel
    @Environment(AppearanceSettings.self) private var appearance
    /// Optional technique to fast-forward to on first appearance — tapping a
    /// technique card lands directly on its example step.
    let focusTechnique: TechniqueID?

    init(lesson: Lesson, focusTechnique: TechniqueID? = nil) {
        _session = State(initialValue: LearningSessionViewModel(lesson: lesson))
        self.focusTechnique = focusTechnique
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            CandidateBoardView(
                grid: session.grid,
                givens: session.lesson.puzzle.map { row in row.map { $0 != 0 } },
                candidates: session.candidates,
                step: session.currentStep
            )
            .padding(.horizontal, 8)

            stepCard

            actionRow

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appearance.backgroundColor.ignoresSafeArea())
        .navigationTitle(session.lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { session.restart() } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .onAppear {
            // Fast-forward past any earlier steps so the focused technique is the
            // first thing the user sees.
            guard let focusTechnique else { return }
            let safety = 200
            var iter = 0
            while iter < safety, let step = session.currentStep, step.technique != focusTechnique {
                session.applyCurrentStep()
                iter += 1
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(session.lesson.blurb)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text("Step \(session.history.count + (session.currentStep == nil ? 0 : 1))")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var stepCard: some View {
        if let step = session.currentStep {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(step.technique.displayName)
                        .font(.headline)
                    Spacer()
                    if !step.units.isEmpty {
                        Text(step.units.map { $0.label }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(.init(step.explanation))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                actionSummary(for: step)
            }
            .padding(14)
            .background(Color.accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        } else if session.isSolved {
            statusCard(icon: "checkmark.seal.fill",
                       tint: .green,
                       title: "Solved!",
                       subtitle: "You walked through every step. Try another lesson.")
        } else if session.stuck {
            statusCard(icon: "puzzlepiece.extension.fill",
                       tint: .orange,
                       title: "Needs a tougher technique",
                       subtitle: "This puzzle requires a strategy that isn't part of this lesson set yet (X-Wing, XY-Wing, etc.).")
        }
    }

    private func actionSummary(for step: LearningStep) -> some View {
        let placements = step.actions.compactMap { action -> String? in
            if case let .place(r, c, d) = action { return "Place \(d) at (\(r + 1),\(c + 1))" }
            return nil
        }
        let elims = step.actions.compactMap { action -> String? in
            if case let .eliminate(r, c, d) = action { return "Erase \(d) from (\(r + 1),\(c + 1))" }
            return nil
        }
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(placements, id: \.self) { Text("· " + $0).font(.caption).foregroundStyle(.green) }
            if elims.count <= 6 {
                ForEach(elims, id: \.self) { Text("· " + $0).font(.caption).foregroundStyle(.red) }
            } else {
                Text("· Erase candidate from \(elims.count) cells").font(.caption).foregroundStyle(.red)
            }
        }
    }

    private func statusCard(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                session.applyCurrentStep()
            } label: {
                Label("Apply Step", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(session.currentStep == nil)
            .opacity(session.currentStep == nil ? 0.4 : 1.0)
        }
        .padding(.horizontal)
    }
}
