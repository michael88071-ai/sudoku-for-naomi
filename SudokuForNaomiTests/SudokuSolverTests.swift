import XCTest
@testable import SudokuForNaomi

final class SudokuSolverTests: XCTestCase {
    /// A known-valid puzzle (1 unique solution).
    static let easyPuzzle: [[Int]] = [
        [5,3,0, 0,7,0, 0,0,0],
        [6,0,0, 1,9,5, 0,0,0],
        [0,9,8, 0,0,0, 0,6,0],

        [8,0,0, 0,6,0, 0,0,3],
        [4,0,0, 8,0,3, 0,0,1],
        [7,0,0, 0,2,0, 0,0,6],

        [0,6,0, 0,0,0, 2,8,0],
        [0,0,0, 4,1,9, 0,0,5],
        [0,0,0, 0,8,0, 0,7,9],
    ]

    func test_isValid_detectsRowCollision() {
        var grid = Self.easyPuzzle
        grid[0][2] = 5  // already 5 in row 0
        XCTAssertFalse(SudokuSolver.isValid(grid, row: 0, col: 5, num: 5))
    }

    func test_isValid_acceptsLegalPlacement() {
        XCTAssertTrue(SudokuSolver.isValid(Self.easyPuzzle, row: 0, col: 2, num: 4))
    }

    func test_solve_findsCompletion() {
        var grid = Self.easyPuzzle
        XCTAssertTrue(SudokuSolver.solve(&grid))
        // Every cell filled, every row contains 1...9
        for r in 0..<9 {
            XCTAssertEqual(Set(grid[r]), Set(1...9), "row \(r) must be a permutation of 1...9")
        }
    }

    func test_countSolutions_uniquePuzzleHasExactlyOne() {
        XCTAssertEqual(SudokuSolver.countSolutions(Self.easyPuzzle, limit: 2), 1)
    }

    func test_countSolutions_emptyGridHasManyHitsLimit() {
        let empty = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        XCTAssertEqual(SudokuSolver.countSolutions(empty, limit: 2), 2)
    }

    func test_countSolutions_ambiguousGridReturnsAtLeastTwo() {
        // A puzzle with too few clues is virtually guaranteed to be ambiguous.
        var grid = Self.easyPuzzle
        grid[0][0] = 0
        grid[0][1] = 0  // remove a couple of clues
        XCTAssertGreaterThanOrEqual(SudokuSolver.countSolutions(grid, limit: 2), 1)
    }
}
