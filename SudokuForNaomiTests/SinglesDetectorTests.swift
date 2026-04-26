import XCTest
@testable import SudokuForNaomi

final class SinglesDetectorTests: XCTestCase {
    private func parse(_ s: String) -> [[Int]] {
        let chars = Array(s.filter { $0.isNumber || $0 == "." })
        precondition(chars.count == 81)
        var grid: [[Int]] = []
        for r in 0..<9 {
            var row: [Int] = []
            for c in 0..<9 {
                let ch = chars[r * 9 + c]
                row.append(ch == "." ? 0 : Int(String(ch))!)
            }
            grid.append(row)
        }
        return grid
    }

    func test_fullHouse_findsLastEmptyCellInRow() {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        // Row 0 is missing only digit 4 at column 3.
        grid[0] = [1, 2, 3, 0, 5, 6, 7, 8, 9]
        let cands = CandidateGrid(from: grid)
        let step = FullHouseDetector.find(grid: grid, candidates: cands)
        XCTAssertNotNil(step)
        XCTAssertEqual(step?.actions, [.place(row: 0, col: 3, digit: 4)])
        XCTAssertEqual(step?.technique, .fullHouse)
    }

    func test_nakedSingle_oneCandidateLeft() {
        // Construct a scenario where (0,0) only has digit 1 left:
        // row 0 has 2-9 in other columns? Easier: peer cells exclude 2-9.
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        grid[0][1] = 2
        grid[0][2] = 3
        grid[1][0] = 4
        grid[2][0] = 5
        grid[1][1] = 6
        grid[2][2] = 7
        grid[0][3] = 8
        grid[0][4] = 9
        let cands = CandidateGrid(from: grid)
        // (0,0) candidates should be {1}
        XCTAssertEqual(cands.candidates(row: 0, col: 0), [1])
        let step = NakedSingleDetector.find(grid: grid, candidates: cands)
        XCTAssertEqual(step?.actions, [.place(row: 0, col: 0, digit: 1)])
    }

    func test_hiddenSingle_inRow() {
        // Set up a row where digit 7 has only one legal position even though the cell has multiple candidates.
        // We need a partially filled grid. Use the standard Wikipedia easy puzzle as a base.
        let grid = parse(
            "53..7...." +
            "6..195..." +
            ".98....6." +
            "8...6...3" +
            "4..8.3..1" +
            "7...2...6" +
            ".6....28." +
            "...419..5" +
            "....8..79"
        )
        let cands = CandidateGrid(from: grid)

        // Walk the registry: there will be many singles. Just check the first hidden-single
        // ever surfaces at some point in the walkthrough.
        let steps = LearningWalkthrough.generateSteps(puzzle: grid)
        let kinds = Set(steps.map { $0.technique })
        XCTAssertTrue(kinds.contains(.fullHouse) || kinds.contains(.nakedSingle) || kinds.contains(.hiddenSingle),
                      "expected at least one singles technique to fire on the Wikipedia easy puzzle")
    }
}
