import Foundation
import Observation

/// Game state for a single Sudoku session. Owned by `GameView`.
///
/// Uses Apple's new `@Observable` macro (iOS 17+) — every stored `var` becomes
/// observable to SwiftUI automatically, no `@Published` needed.
@MainActor
@Observable
final class GameViewModel {
    enum Phase: Equatable, Hashable {
        case playing
        case paused
        case won
        case quit
        case failed
    }

    let difficulty: Difficulty
    let startedAt: Date
    var board: SudokuBoard
    var phase: Phase = .playing
    var mistakeCount: Int = 0
    var elapsedSeconds: Int = 0
    var selectedCell: SudokuBoard.Coord?

    /// Snapshot of the most recently requested hint. Drives the flashing cell
    /// and the info panel below the board.
    struct HintContext: Equatable {
        let grid: [[Int]]
        let givens: [[Bool]]
        let candidates: CandidateGrid
        let step: LearningStep
        let target: SudokuBoard.Coord
    }

    /// The cell that should currently be flashing as a hint. Cleared 3 seconds
    /// after `requestHint()` runs.
    var hintCell: SudokuBoard.Coord?
    /// The most recent hint, kept around for the info panel even after the flash fades.
    var latestHint: HintContext?

    /// Internal timer accounting. Not user-facing.
    @ObservationIgnored private var lastResumeTick: Date
    @ObservationIgnored private var accumulatedSeconds: Int = 0
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var hintFlashTask: Task<Void, Never>?

    init(difficulty: Difficulty, board: SudokuBoard, startedAt: Date = .now) {
        self.difficulty = difficulty
        self.board = board
        self.startedAt = startedAt
        self.lastResumeTick = startedAt
    }

    // MARK: - Derived UI helpers

    var conflictingCells: Set<SudokuBoard.Coord> {
        board.conflictingCells()
    }

    /// Cells sharing the selected cell's value — used to gently guide the eye.
    var peerHighlightedCells: Set<SudokuBoard.Coord> {
        guard let sel = selectedCell else { return [] }
        let value = board.value(row: sel.row, col: sel.col)
        guard value != 0 else { return [] }
        var result: Set<SudokuBoard.Coord> = []
        for r in 0..<9 {
            for c in 0..<9 where board.grid[r][c] == value {
                result.insert(.init(r, c))
            }
        }
        return result
    }

    /// True iff the value placed by the user at (row, col) differs from the unique solution.
    /// Givens are never mistakes.
    func isMistake(row: Int, col: Int) -> Bool {
        guard !board.isGiven(row: row, col: col) else { return false }
        let v = board.value(row: row, col: col)
        return v != 0 && v != board.solutionValue(row: row, col: col)
    }

    // MARK: - User actions

    /// Place `value` (1–9) at the currently selected cell. `0` clears it.
    /// Increments `mistakeCount` if the value disagrees with the solution.
    func place(_ value: Int) {
        guard phase == .playing,
              let sel = selectedCell,
              !board.isGiven(row: sel.row, col: sel.col),
              (0...9).contains(value) else { return }

        let previous = board.grid[sel.row][sel.col]
        board.grid[sel.row][sel.col] = value

        let isWrong = value != 0 && value != board.solutionValue(row: sel.row, col: sel.col)
        // Penalize each distinct wrong placement — but tapping the same wrong value
        // twice in a row shouldn't double-count.
        if isWrong && value != previous {
            mistakeCount += 1
        }

        if board.isSolved {
            phase = .won
            stopTimer()
        }
    }

    func clearSelected() { place(0) }

    /// Find the next-easiest cell to fill given the current correct progress
    /// and flash it for 3 seconds. Wrong user entries are ignored when running
    /// the detectors so a mistake elsewhere doesn't poison the hint search.
    func requestHint() {
        guard phase == .playing else { return }

        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        for r in 0..<9 {
            for c in 0..<9 {
                let v = board.grid[r][c]
                if v != 0 && v == board.solution[r][c] {
                    grid[r][c] = v
                }
            }
        }
        let candidates = CandidateGrid(from: grid)
        guard let step = LearningWalkthrough.nextStep(grid: grid, candidates: candidates) else { return }

        let target: SudokuBoard.Coord
        if let placement = step.actions.first(where: {
            if case .place = $0 { return true } else { return false }
        }), case let .place(r, c, _) = placement {
            target = SudokuBoard.Coord(r, c)
        } else if let first = step.actions.first {
            switch first {
            case .place(let r, let c, _), .eliminate(let r, let c, _):
                target = SudokuBoard.Coord(r, c)
            }
        } else if let highlight = step.highlights.first(where: { $0.role == .target }) {
            target = SudokuBoard.Coord(highlight.row, highlight.col)
        } else {
            return
        }

        latestHint = HintContext(
            grid: grid,
            givens: board.givens,
            candidates: candidates,
            step: step,
            target: target
        )
        hintCell = target

        hintFlashTask?.cancel()
        hintFlashTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                if self.hintCell == target {
                    self.hintCell = nil
                }
            }
        }
    }

    func quit() {
        guard phase == .playing || phase == .paused else { return }
        phase = .quit
        stopTimer()
    }

    func markFailed() {
        guard phase == .playing || phase == .paused else { return }
        phase = .failed
        stopTimer()
    }

    func pause() {
        guard phase == .playing else { return }
        stopTimer()
        phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .playing
        startTimer()
    }

    /// Wipe all user-entered cells, reset mistake/time counters, restart timer.
    func reset() {
        for r in 0..<9 {
            for c in 0..<9 where !board.givens[r][c] {
                board.grid[r][c] = 0
            }
        }
        mistakeCount = 0
        accumulatedSeconds = 0
        elapsedSeconds = 0
        lastResumeTick = .now
        selectedCell = nil
        hintCell = nil
        latestHint = nil
        hintFlashTask?.cancel()
        hintFlashTask = nil
        if phase != .playing {
            phase = .playing
            startTimer()
        }
    }

    // MARK: - Timer

    func startTimer() {
        guard timerTask == nil else { return }
        lastResumeTick = .now
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await self?.tick()
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        accumulatedSeconds += Int(Date.now.timeIntervalSince(lastResumeTick))
        elapsedSeconds = accumulatedSeconds
    }

    private func tick() {
        guard phase == .playing else { return }
        elapsedSeconds = accumulatedSeconds + Int(Date.now.timeIntervalSince(lastResumeTick))
    }

    // MARK: - Persistence helper

    /// Build the `GameRecord` to persist. Returns nil if the game is still in progress.
    func toGameRecord() -> GameRecord? {
        let status: GameStatus
        switch phase {
        case .won: status = .won
        case .quit: status = .quit
        case .failed: status = .failed
        case .playing, .paused: return nil
        }
        return GameRecord(
            startedAt: startedAt,
            endedAt: .now,
            difficulty: difficulty,
            status: status,
            elapsedSeconds: elapsedSeconds,
            mistakeCount: mistakeCount
        )
    }
}
