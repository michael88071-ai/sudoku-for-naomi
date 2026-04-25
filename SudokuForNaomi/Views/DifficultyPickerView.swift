import SwiftUI

struct DifficultyPickerView: View {
    @Binding var path: NavigationPath

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Difficulty")
                .font(.largeTitle.bold())
                .padding(.top, 24)

            VStack(spacing: 14) {
                ForEach(Difficulty.allCases) { difficulty in
                    Button {
                        path.removeLast()
                        path.append(HomeRoute.game(difficulty))
                    } label: {
                        difficultyRow(difficulty)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()
        }
        .navigationTitle("New Game")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func difficultyRow(_ d: Difficulty) -> some View {
        HStack(spacing: 16) {
            Image(systemName: d.systemImageName)
                .font(.title2)
                .frame(width: 36)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(d.displayName)
                    .font(.title3.weight(.semibold))
                Text("\(d.targetClueCount) clues")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        DifficultyPickerView(path: .constant(NavigationPath()))
    }
}
