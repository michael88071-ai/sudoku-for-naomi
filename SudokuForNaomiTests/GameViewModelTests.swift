import XCTest
@testable import SudokuForNaomi

@MainActor
final class GameViewModelTests: XCTestCase {
    /// Build a VM whose puzzle has exactly one empty cell at (0,0). The solution there is `expected`.
    private func makeNearlyComplete(expected: Int) -> GameViewModel {
        var solution = [[Int]]()
        // Construct a known solved 9x9 (any valid one will do).
        let base: [[Int]] = [
            [1,2,3,4,5,6,7,8,9],
            [4,5,6,7,8,9,1,2,3],
            [7,8,9,1,2,3,4,5,6],
            [2,3,4,5,6,7,8,9,1],
            [5,6,7,8,9,1,2,3,4],
            [8,9,1,2,3,4,5,6,7],
            [3,4,5,6,7,8,9,1,2],
            [6,7,8,9,1,2,3,4,5],
            [9,1,2,3,4,5,6,7,8],
        ]
        solution = base
        var puzzle = solution
        // Pick a coordinate where solution is `expected`. If it isn't, swap it in.
        // For base[0][0] == 1, so passing expected=1 works directly.
        puzzle[0][0] = 0
        return GameViewModel(
            difficulty: .easy,
            board: SudokuBoard(puzzle: puzzle, solution: solution)
        )
    }

    func test_correctMove_winsTheGame() {
        let vm = makeNearlyComplete(expected: 1)
        vm.selectedCell = .init(0, 0)
        vm.place(1)
        XCTAssertEqual(vm.phase, .won)
        XCTAssertEqual(vm.mistakeCount, 0)
    }

    func test_wrongMove_incrementsMistakeCount() {
        let vm = makeNearlyComplete(expected: 1)
        vm.selectedCell = .init(0, 0)
        vm.place(2)  // wrong
        XCTAssertEqual(vm.mistakeCount, 1)
        XCTAssertEqual(vm.phase, .playing)
    }

    func test_repeatingSameWrongMove_doesNotIncrementTwice() {
        let vm = makeNearlyComplete(expected: 1)
        vm.selectedCell = .init(0, 0)
        vm.place(2)
        vm.place(2)  // same wrong value — shouldn't double-count
        XCTAssertEqual(vm.mistakeCount, 1)
    }

    func test_givenCells_areImmutable() {
        let vm = makeNearlyComplete(expected: 1)
        vm.selectedCell = .init(0, 1)  // a given cell
        let before = vm.board.value(row: 0, col: 1)
        vm.place(7)
        XCTAssertEqual(vm.board.value(row: 0, col: 1), before)
    }

    func test_quit_endsGame() {
        let vm = makeNearlyComplete(expected: 1)
        vm.quit()
        XCTAssertEqual(vm.phase, .quit)
        XCTAssertNotNil(vm.toGameRecord())
        XCTAssertEqual(vm.toGameRecord()?.status, .quit)
    }

    func test_markFailed_endsGame() {
        let vm = makeNearlyComplete(expected: 1)
        vm.markFailed()
        XCTAssertEqual(vm.phase, .failed)
        XCTAssertEqual(vm.toGameRecord()?.status, .failed)
    }

    func test_reset_clearsUserEntriesAndMistakes() {
        let vm = makeNearlyComplete(expected: 1)
        vm.selectedCell = .init(0, 0)
        vm.place(2)  // wrong
        XCTAssertEqual(vm.mistakeCount, 1)

        vm.reset()
        XCTAssertEqual(vm.mistakeCount, 0)
        XCTAssertEqual(vm.board.value(row: 0, col: 0), 0)
        XCTAssertEqual(vm.elapsedSeconds, 0)
    }

    func test_inProgressGame_hasNoRecord() {
        let vm = makeNearlyComplete(expected: 1)
        XCTAssertNil(vm.toGameRecord())
    }

    func test_requestHint_flashesTheNextEasiestCell() {
        let vm = makeNearlyComplete(expected: 1)
        vm.requestHint()
        XCTAssertEqual(vm.hintCell, .init(0, 0))
        XCTAssertNotNil(vm.latestHint)
        XCTAssertEqual(vm.latestHint?.target, .init(0, 0))
    }

    func test_requestHint_ignoresWrongUserEntries() {
        let vm = makeNearlyComplete(expected: 1)
        // Drop a wrong value in a different cell. The hint must still find the
        // (0,0) full-house regardless of the mistake elsewhere.
        vm.selectedCell = .init(8, 8)
        vm.place(1)  // wrong (solution at 8,8 is 8)
        vm.requestHint()
        XCTAssertEqual(vm.hintCell, .init(0, 0))
    }

    func test_reset_clearsHintState() {
        let vm = makeNearlyComplete(expected: 1)
        vm.requestHint()
        XCTAssertNotNil(vm.hintCell)

        vm.reset()
        XCTAssertNil(vm.hintCell)
        XCTAssertNil(vm.latestHint)
    }
}
