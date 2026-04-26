import SwiftUI

/// Picker screen for Learning Mode. Shows two sections:
///   - "Lessons" — start a curated puzzle and walk through every step.
///   - "Techniques" — jump straight to the first example of a specific technique.
struct LearnView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                lessonsSection
                techniquesSection
            }
            .padding(20)
        }
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Solving Techniques")
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text("Step through real puzzles to see how the patterns appear and why each move is forced.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lessons")
                .font(.headline)
            ForEach(LessonCatalog.lessons) { lesson in
                Button {
                    path.append(HomeRoute.lesson(lesson.id))
                } label: {
                    lessonRow(lesson)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func lessonRow(_ lesson: Lesson) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "book.closed.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.title)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(lesson.blurb)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var techniquesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Techniques")
                .font(.headline)
            ForEach(TechniqueID.allCases.sorted(by: { $0.priority < $1.priority })) { tech in
                techniqueRow(tech)
            }
        }
    }

    private func techniqueRow(_ tech: TechniqueID) -> some View {
        let example = TechniqueLessonFinder.firstExample(of: tech)
        return Group {
            if let example {
                Button {
                    path.append(HomeRoute.techniqueExample(tech))
                } label: {
                    rowContent(tech: tech, available: true)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens lesson '\(example.lesson.title)' at the first \(tech.displayName) step")
            } else {
                rowContent(tech: tech, available: false)
                    .opacity(0.5)
            }
        }
    }

    private func rowContent(tech: TechniqueID, available: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: available ? "lightbulb.fill" : "lightbulb")
                .foregroundStyle(available ? Color.yellow : Color.secondary)
                .font(.title3)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(tech.displayName)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(tech.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                if !available {
                    Text("No example in current lessons.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if available {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
