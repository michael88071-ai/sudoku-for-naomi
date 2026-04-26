import XCTest
@testable import SudokuForNaomi

final class CandidateGridTests: XCTestCase {
    private static let emptyRow = Array(repeating: 0, count: 9)
    private static let emptyGrid = Array(repeating: emptyRow, count: 9)

    func test_emptyGrid_allCellsHaveAllNineCandidates() {
        let cg = CandidateGrid(from: Self.emptyGrid)
        for r in 0..<9 {
            for c in 0..<9 {
                XCTAssertEqual(cg.candidates(row: r, col: c), Set(1...9), "(\(r),\(c))")
            }
        }
    }

    func test_filledCellsHaveNoCandidates() {
        var grid = Self.emptyGrid
        grid[0][0] = 5
        let cg = CandidateGrid(from: grid)
        XCTAssertTrue(cg.candidates(row: 0, col: 0).isEmpty)
    }

    func test_peerOf5_doesNotInclude5() {
        var grid = Self.emptyGrid
        grid[0][0] = 5
        let cg = CandidateGrid(from: grid)
        XCTAssertFalse(cg.contains(5, row: 0, col: 5))   // same row
        XCTAssertFalse(cg.contains(5, row: 5, col: 0))   // same col
        XCTAssertFalse(cg.contains(5, row: 1, col: 1))   // same box
        XCTAssertTrue(cg.contains(5, row: 5, col: 5))    // unrelated
    }

    func test_place_eliminatesFromRowColBox() {
        var cg = CandidateGrid(from: Self.emptyGrid)
        cg.place(7, row: 4, col: 4)
        XCTAssertTrue(cg.candidates(row: 4, col: 4).isEmpty)
        XCTAssertFalse(cg.contains(7, row: 4, col: 0))   // row
        XCTAssertFalse(cg.contains(7, row: 0, col: 4))   // col
        XCTAssertFalse(cg.contains(7, row: 5, col: 5))   // box
        XCTAssertTrue(cg.contains(7, row: 0, col: 0))    // unrelated still has 7
    }

    func test_eliminate_removesSingleDigit() {
        var cg = CandidateGrid(from: Self.emptyGrid)
        cg.eliminate(3, row: 2, col: 2)
        XCTAssertFalse(cg.contains(3, row: 2, col: 2))
        XCTAssertEqual(cg.count(row: 2, col: 2), 8)
    }
}
