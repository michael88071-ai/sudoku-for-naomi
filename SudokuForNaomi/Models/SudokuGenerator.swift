import Foundation

enum SudokuGenerator {
    /// Generate a fully solved 9×9 grid via randomized backtracking.
    static func generateSolvedGrid(rng: inout SystemRandomNumberGenerator) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillRandom(&grid, rng: &rng)
        return grid
    }

    private static func fillRandom(_ grid: inout [[Int]], rng: inout SystemRandomNumberGenerator) -> Bool {
        guard let (r, c) = findEmpty(grid) else { return true }
        let nums = (1...9).shuffled(using: &rng)
        for n in nums where SudokuSolver.isValid(grid, row: r, col: c, num: n) {
            grid[r][c] = n
            if fillRandom(&grid, rng: &rng) { return true }
            grid[r][c] = 0
        }
        return false
    }

    private static func findEmpty(_ grid: [[Int]]) -> (Int, Int)? {
        for r in 0..<9 {
            for c in 0..<9 {
                if grid[r][c] == 0 { return (r, c) }
            }
        }
        return nil
    }

    /// Generate a (puzzle, solution) pair for the given difficulty.
    ///
    /// Strategy: build a full solution, then iteratively blank out cells (with their
    /// 180° rotational partners, for visual symmetry) while ensuring the remaining
    /// puzzle still has a unique completion. We may stop short of `targetClueCount`
    /// if too many removals would break uniqueness — that's fine; the puzzle is still
    /// valid, just slightly easier than the target.
    static func generatePuzzle(difficulty: Difficulty) -> (puzzle: [[Int]], solution: [[Int]]) {
        var rng = SystemRandomNumberGenerator()
        let solution = generateSolvedGrid(rng: &rng)
        var puzzle = solution

        let target = difficulty.targetClueCount
        let cellsToRemove = 81 - target

        // Build a list of symmetric pairs (the cell and its 180° rotation).
        // The center cell (4,4) pairs with itself.
        var pairs: [[(Int, Int)]] = []
        var seen = Set<Int>()
        for r in 0..<9 {
            for c in 0..<9 {
                let key = r * 9 + c
                if seen.contains(key) { continue }
                let mirror = (8 - r, 8 - c)
                let mirrorKey = mirror.0 * 9 + mirror.1
                seen.insert(key)
                seen.insert(mirrorKey)
                if key == mirrorKey {
                    pairs.append([(r, c)])
                } else {
                    pairs.append([(r, c), mirror])
                }
            }
        }
        pairs.shuffle(using: &rng)

        var removed = 0
        for pair in pairs {
            if removed >= cellsToRemove { break }
            // Try removing this whole pair atomically.
            let backups = pair.map { puzzle[$0.0][$0.1] }
            for (r, c) in pair { puzzle[r][c] = 0 }

            if SudokuSolver.countSolutions(puzzle, limit: 2) == 1 {
                removed += pair.count
            } else {
                // Restore — would create ambiguity.
                for (i, (r, c)) in pair.enumerated() { puzzle[r][c] = backups[i] }
            }
        }

        return (puzzle, solution)
    }
}
