import Foundation

/// Pencil-mark state for a 9×9 grid: for every empty cell, the set of digits 1–9
/// that are still legal given current row/col/box constraints. Filled cells have
/// an empty candidate set (the placed digit lives in the regular grid).
struct CandidateGrid: Equatable {
    /// `cells[r][c]` is a 9-bit mask. Bit `(d-1)` set means digit `d` is a candidate.
    private(set) var cells: [[UInt16]]

    init() {
        self.cells = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    }

    /// Build pencil marks from a partially-filled grid by eliminating digits that
    /// already appear in the row/col/box of each empty cell.
    init(from grid: [[Int]]) {
        var cells: [[UInt16]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        for r in 0..<9 {
            for c in 0..<9 where grid[r][c] == 0 {
                var mask: UInt16 = 0b111_111_111
                // Eliminate row peers
                for cc in 0..<9 {
                    let v = grid[r][cc]
                    if v != 0 { mask &= ~(1 << (v - 1)) }
                }
                // Column peers
                for rr in 0..<9 {
                    let v = grid[rr][c]
                    if v != 0 { mask &= ~(1 << (v - 1)) }
                }
                // Box peers
                let br = (r / 3) * 3, bc = (c / 3) * 3
                for rr in br..<br+3 {
                    for cc in bc..<bc+3 {
                        let v = grid[rr][cc]
                        if v != 0 { mask &= ~(1 << (v - 1)) }
                    }
                }
                cells[r][c] = mask
            }
        }
        self.cells = cells
    }

    /// Set of candidate digits (1–9) at the given cell.
    func candidates(row: Int, col: Int) -> Set<Int> {
        let mask = cells[row][col]
        var out: Set<Int> = []
        for d in 1...9 where (mask & (1 << (d - 1))) != 0 { out.insert(d) }
        return out
    }

    /// Raw candidate bitmask (bit d-1 set means digit d is a candidate).
    func mask(row: Int, col: Int) -> UInt16 { cells[row][col] }

    /// True if digit `d` (1-9) is a candidate at (row, col).
    func contains(_ d: Int, row: Int, col: Int) -> Bool {
        cells[row][col] & (1 << (d - 1)) != 0
    }

    /// Number of candidate digits at (row, col).
    func count(row: Int, col: Int) -> Int {
        cells[row][col].nonzeroBitCount
    }

    /// Remove a candidate digit. No-op if not present.
    mutating func eliminate(_ d: Int, row: Int, col: Int) {
        cells[row][col] &= ~(1 << (d - 1))
    }

    /// Place a digit: clears candidates at (row,col) and eliminates `d` from peers.
    mutating func place(_ d: Int, row: Int, col: Int) {
        cells[row][col] = 0
        let bit: UInt16 = ~(1 << (d - 1))
        for cc in 0..<9 { cells[row][cc] &= bit }
        for rr in 0..<9 { cells[rr][col] &= bit }
        let br = (row / 3) * 3, bc = (col / 3) * 3
        for rr in br..<br+3 {
            for cc in bc..<bc+3 {
                cells[rr][cc] &= bit
            }
        }
    }
}
