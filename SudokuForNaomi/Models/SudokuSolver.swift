import Foundation

/// Backtracking Sudoku solver.
///
/// Two entry points:
/// - `solve(_:)` returns a single solution if one exists.
/// - `countSolutions(_:limit:)` counts solutions up to `limit`. The generator uses
///   `limit: 2` to verify a puzzle has exactly one solution.
enum SudokuSolver {
    /// Attempts to fill `grid` in place. Returns true if a valid completion was found.
    @discardableResult
    static func solve(_ grid: inout [[Int]]) -> Bool {
        guard let (r, c) = findEmpty(grid) else { return true }
        for n in 1...9 where isValid(grid, row: r, col: c, num: n) {
            grid[r][c] = n
            if solve(&grid) { return true }
            grid[r][c] = 0
        }
        return false
    }

    /// Returns min(actual solution count, limit). Useful for uniqueness checks.
    static func countSolutions(_ grid: [[Int]], limit: Int = 2) -> Int {
        var working = grid
        var count = 0
        countHelper(&working, count: &count, limit: limit)
        return count
    }

    private static func countHelper(_ grid: inout [[Int]], count: inout Int, limit: Int) {
        if count >= limit { return }
        guard let (r, c) = findEmpty(grid) else {
            count += 1
            return
        }
        for n in 1...9 where isValid(grid, row: r, col: c, num: n) {
            grid[r][c] = n
            countHelper(&grid, count: &count, limit: limit)
            if count >= limit {
                grid[r][c] = 0
                return
            }
            grid[r][c] = 0
        }
    }

    /// True if placing `num` at (row, col) violates no Sudoku rule.
    static func isValid(_ grid: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        for i in 0..<9 {
            if grid[row][i] == num { return false }
            if grid[i][col] == num { return false }
        }
        let br = (row / 3) * 3
        let bc = (col / 3) * 3
        for r in br..<br+3 {
            for c in bc..<bc+3 {
                if grid[r][c] == num { return false }
            }
        }
        return true
    }

    private static func findEmpty(_ grid: [[Int]]) -> (Int, Int)? {
        for r in 0..<9 {
            for c in 0..<9 {
                if grid[r][c] == 0 { return (r, c) }
            }
        }
        return nil
    }
}
