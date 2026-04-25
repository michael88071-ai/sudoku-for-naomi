import Foundation

/// 9×9 Sudoku board state.
///
/// `grid` holds the player-visible values (0 = empty, 1–9 = filled).
/// `solution` holds the unique correct answer for every cell.
/// `givens` marks the cells that were pre-filled by the puzzle and cannot be edited.
struct SudokuBoard: Equatable, Codable {
    static let size = 9
    static let boxSize = 3

    var grid: [[Int]]            // 9×9, 0 means empty
    var solution: [[Int]]        // 9×9, all 1–9
    var givens: [[Bool]]         // 9×9, true = clue, immutable

    init(grid: [[Int]], solution: [[Int]], givens: [[Bool]]) {
        precondition(grid.count == 9 && grid.allSatisfy { $0.count == 9 })
        precondition(solution.count == 9 && solution.allSatisfy { $0.count == 9 })
        precondition(givens.count == 9 && givens.allSatisfy { $0.count == 9 })
        self.grid = grid
        self.solution = solution
        self.givens = givens
    }

    /// Build a board from a freshly-generated puzzle/solution pair.
    init(puzzle: [[Int]], solution: [[Int]]) {
        let givens = puzzle.map { row in row.map { $0 != 0 } }
        self.init(grid: puzzle, solution: solution, givens: givens)
    }

    func isGiven(row: Int, col: Int) -> Bool { givens[row][col] }
    func value(row: Int, col: Int) -> Int { grid[row][col] }
    func solutionValue(row: Int, col: Int) -> Int { solution[row][col] }

    /// True if every cell matches the solution.
    var isSolved: Bool { grid == solution }

    /// Cells in the same row/column/3×3 box that share a value, indicating a rule conflict.
    /// Returned as a set of (row, col) coordinates the caller can highlight in red.
    func conflictingCells() -> Set<Coord> {
        var conflicts: Set<Coord> = []
        // Rows
        for r in 0..<9 {
            var seen: [Int: Coord] = [:]
            for c in 0..<9 {
                let v = grid[r][c]
                guard v != 0 else { continue }
                if let prior = seen[v] {
                    conflicts.insert(prior)
                    conflicts.insert(Coord(r, c))
                } else {
                    seen[v] = Coord(r, c)
                }
            }
        }
        // Columns
        for c in 0..<9 {
            var seen: [Int: Coord] = [:]
            for r in 0..<9 {
                let v = grid[r][c]
                guard v != 0 else { continue }
                if let prior = seen[v] {
                    conflicts.insert(prior)
                    conflicts.insert(Coord(r, c))
                } else {
                    seen[v] = Coord(r, c)
                }
            }
        }
        // 3×3 boxes
        for br in stride(from: 0, to: 9, by: 3) {
            for bc in stride(from: 0, to: 9, by: 3) {
                var seen: [Int: Coord] = [:]
                for r in br..<br+3 {
                    for c in bc..<bc+3 {
                        let v = grid[r][c]
                        guard v != 0 else { continue }
                        if let prior = seen[v] {
                            conflicts.insert(prior)
                            conflicts.insert(Coord(r, c))
                        } else {
                            seen[v] = Coord(r, c)
                        }
                    }
                }
            }
        }
        return conflicts
    }

    struct Coord: Hashable, Codable {
        let row: Int
        let col: Int
        init(_ row: Int, _ col: Int) { self.row = row; self.col = col }
    }
}
