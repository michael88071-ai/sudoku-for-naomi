import XCTest
@testable import SudokuForNaomi

final class SudokuGeneratorTests: XCTestCase {
    func test_generateSolvedGrid_isValidCompletion() {
        var rng = SystemRandomNumberGenerator()
        let grid = SudokuGenerator.generateSolvedGrid(rng: &rng)
        for r in 0..<9 {
            XCTAssertEqual(Set(grid[r]), Set(1...9), "row \(r)")
        }
        for c in 0..<9 {
            let col = (0..<9).map { grid[$0][c] }
            XCTAssertEqual(Set(col), Set(1...9), "col \(c)")
        }
        for br in stride(from: 0, to: 9, by: 3) {
            for bc in stride(from: 0, to: 9, by: 3) {
                var box: [Int] = []
                for r in br..<br+3 { for c in bc..<bc+3 { box.append(grid[r][c]) } }
                XCTAssertEqual(Set(box), Set(1...9), "box (\(br),\(bc))")
            }
        }
    }

    func test_generatePuzzle_solutionMatchesPuzzleClues() throws {
        for diff in Difficulty.allCases {
            let result = SudokuGenerator.generatePuzzle(difficulty: diff)
            for r in 0..<9 {
                for c in 0..<9 where result.puzzle[r][c] != 0 {
                    XCTAssertEqual(
                        result.puzzle[r][c], result.solution[r][c],
                        "[\(diff)] clue at (\(r),\(c)) must match solution"
                    )
                }
            }
        }
    }

    func test_generatePuzzle_isUniquelySolvable() {
        for diff in Difficulty.allCases {
            let result = SudokuGenerator.generatePuzzle(difficulty: diff)
            let count = SudokuSolver.countSolutions(result.puzzle, limit: 2)
            XCTAssertEqual(count, 1, "[\(diff)] puzzle should have exactly one solution")
        }
    }

    func test_generatePuzzle_clueCountInExpectedRange() {
        for diff in Difficulty.allCases {
            let result = SudokuGenerator.generatePuzzle(difficulty: diff)
            let clues = result.puzzle.flatMap { $0 }.filter { $0 != 0 }.count
            // Generator removes cells in symmetric pairs, so it may overshoot the
            // target by one cell (and may undershoot if uniqueness constraints
            // block further removals). Either way, the count should be sane.
            XCTAssertGreaterThanOrEqual(clues, diff.targetClueCount - 1, "[\(diff)] clue count \(clues) should be ~>= target \(diff.targetClueCount)")
            XCTAssertLessThanOrEqual(clues, 81)
        }
    }
}
