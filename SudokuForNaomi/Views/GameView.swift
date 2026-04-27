import SwiftUI
import SwiftData

struct GameView: View {
    let difficulty: Difficulty
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Environment(AppearanceSettings.self) private var appearance

    @State private var viewModel: GameViewModel?
    @State private var endResult: EndResult?
    @State private var showQuitConfirm = false
    @State private var showResetConfirm = false
    @State private var showHintInfo = false

    /// Snapshot of the final game state, used to drive the GameOver sheet.
    struct EndResult: Identifiable {
        let id = UUID()
        let status: GameStatus
        let difficulty: Difficulty
        let elapsedSeconds: Int
        let mistakeCount: Int
    }

    var body: some View {
        VStack(spacing: 0) {
            if let vm = viewModel {
                topBar(vm: vm)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                BoardView(viewModel: vm)
                    .padding(.horizontal, 12)

                hintInfoRow(vm: vm)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                Spacer(minLength: 8)

                NumberPadView(viewModel: vm)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)

                actionRow
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            } else {
                Spacer()
                ProgressView("Generating puzzle…")
                    .controlSize(.large)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appearance.backgroundColor.ignoresSafeArea())
        .task {
            await loadIfNeeded()
        }
        .onDisappear {
            viewModel?.stopTimer()
        }
        .alert("Quit Game?", isPresented: $showQuitConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Quit", role: .destructive) { endGame(.quit) }
        } message: {
            Text("This game will be saved as Quit in your history.")
        }
        .alert("Reset Board?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { viewModel?.reset() }
        } message: {
            Text("Erases your entries and restarts the timer. Difficulty stays the same.")
        }
        .sheet(item: $endResult) { result in
            GameOverView(result: result) {
                path = NavigationPath()
            }
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showHintInfo) {
            if let hint = viewModel?.latestHint {
                HintInfoPanelView(hint: hint)
            }
        }
        .onChange(of: viewModel?.phase) { _, new in
            if new == .won, let vm = viewModel, endResult == nil {
                persistAndPresentResult(status: .won, vm: vm)
            }
        }
    }

    // MARK: - Lifecycle

    private func loadIfNeeded() async {
        guard viewModel == nil else { return }
        let board = await Task.detached(priority: .userInitiated) {
            let result = SudokuGenerator.generatePuzzle(difficulty: difficulty)
            return SudokuBoard(puzzle: result.puzzle, solution: result.solution)
        }.value
        let vm = GameViewModel(difficulty: difficulty, board: board)
        viewModel = vm
        vm.startTimer()
    }

    private func endGame(_ status: GameStatus) {
        guard let vm = viewModel, endResult == nil else { return }
        switch status {
        case .quit: vm.quit()
        case .failed: vm.markFailed()
        case .won: break  // already set by VM
        }
        persistAndPresentResult(status: status, vm: vm)
    }

    private func persistAndPresentResult(status: GameStatus, vm: GameViewModel) {
        if let record = vm.toGameRecord() {
            modelContext.insert(record)
            try? modelContext.save()
        }
        endResult = EndResult(
            status: status,
            difficulty: vm.difficulty,
            elapsedSeconds: vm.elapsedSeconds,
            mistakeCount: vm.mistakeCount
        )
    }

    // MARK: - Subviews

    @ViewBuilder
    private func topBar(vm: GameViewModel) -> some View {
        HStack {
            Button {
                if vm.phase == .playing || vm.phase == .paused {
                    showQuitConfirm = true
                } else {
                    path = NavigationPath()
                }
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.title3.weight(.semibold))
                    .padding(8)
            }

            Spacer()

            Text(vm.difficulty.displayName.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle\(vm.mistakeCount > 0 ? ".fill" : "")")
                Text("\(vm.mistakeCount)")
            }
            .font(.subheadline.weight(.medium).monospacedDigit())
            .foregroundStyle(vm.mistakeCount > 0 ? Color.red : Color.secondary)

            Spacer()

            Text(formatTime(vm.elapsedSeconds))
                .font(.title3.weight(.semibold).monospacedDigit())

            Spacer()

            Button {
                if vm.phase == .playing { vm.pause() } else if vm.phase == .paused { vm.resume() }
            } label: {
                Image(systemName: vm.phase == .paused ? "play.fill" : "pause.fill")
                    .font(.title3)
                    .padding(8)
            }
        }
        .padding(.horizontal, 8)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            actionButton(label: "Reset", systemImage: "arrow.counterclockwise") {
                showResetConfirm = true
            }
            actionButton(label: "Hint", systemImage: "lightbulb.fill") {
                viewModel?.requestHint()
            }
            actionButton(label: "Quit", systemImage: "xmark", role: .destructive) {
                showQuitConfirm = true
            }
        }
    }

    @ViewBuilder
    private func hintInfoRow(vm: GameViewModel) -> some View {
        HStack(spacing: 8) {
            Spacer()
            Button {
                showHintInfo = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                    if let hint = vm.latestHint {
                        Text(hint.step.technique.displayName)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                    } else {
                        Text("No hint yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(vm.latestHint == nil)
            .opacity(vm.latestHint == nil ? 0.5 : 1.0)
        }
    }

    private func actionButton(
        label: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
