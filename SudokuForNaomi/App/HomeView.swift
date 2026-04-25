import SwiftUI

/// Routes pushed onto the root NavigationStack from the home screen.
enum HomeRoute: Hashable {
    case difficultyPicker
    case game(Difficulty)
    case history
}

struct HomeView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Sudoku")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                    Text("for Naomi")
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 14) {
                    primaryButton(title: "New Game", systemImage: "play.fill") {
                        path.append(HomeRoute.difficultyPicker)
                    }
                    secondaryButton(title: "History", systemImage: "clock.arrow.circlepath") {
                        path.append(HomeRoute.history)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .difficultyPicker:
                    DifficultyPickerView(path: $path)
                case .game(let difficulty):
                    GameView(difficulty: difficulty, path: $path)
                        .navigationBarBackButtonHidden(true)
                case .history:
                    HistoryView()
                }
            }
        }
    }

    private func primaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: GameRecord.self, inMemory: true)
}
