import XCTest
@testable import SudokuForNaomi

final class SudokuBoardTests: XCTestCase {
    private static let solution: [[Int]] = [
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

    func test_isSolved_trueWhenGridMatchesSolution() {
        let board = SudokuBoard(puzzle: Self.solution, solution: Self.solution)
        XCTAssertTrue(board.isSolved)
    }

    func test_isSolved_falseWhenAnyCellEmpty() {
        var puzzle = Self.solution
        puzzle[0][0] = 0
        let board = SudokuBoard(puzzle: puzzle, solution: Self.solution)
        XCTAssertFalse(board.isSolved)
    }

    func test_givens_markedFromNonZeroCells() {
        var puzzle = Self.solution
        puzzle[0][0] = 0
        puzzle[5][5] = 0
        let board = SudokuBoard(puzzle: puzzle, solution: Self.solution)
        XCTAssertFalse(board.isGiven(row: 0, col: 0))
        XCTAssertFalse(board.isGiven(row: 5, col: 5))
        XCTAssertTrue(board.isGiven(row: 1, col: 1))
    }

    func test_conflictingCells_detectsRowDuplicates() {
        var grid = Self.solution
        grid[0][0] = 2  // row 0 now has two 2s (positions 0 and 1)
        let board = SudokuBoard(grid: grid, solution: Self.solution, givens: Array(repeating: Array(repeating: false, count: 9), count: 9))
        let conflicts = board.conflictingCells()
        XCTAssertTrue(conflicts.contains(.init(0, 0)))
        XCTAssertTrue(conflicts.contains(.init(0, 1)))
    }

    func test_conflictingCells_emptyOnValidGrid() {
        let board = SudokuBoard(puzzle: Self.solution, solution: Self.solution)
        XCTAssertTrue(board.conflictingCells().isEmpty)
    }
}
