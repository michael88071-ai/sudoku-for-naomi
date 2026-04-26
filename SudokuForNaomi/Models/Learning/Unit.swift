import Foundation

/// A "unit" in Sudoku terminology is one of the 27 groups that must contain each
/// digit 1–9 exactly once: 9 rows, 9 columns, 9 boxes.
enum Unit: Hashable {
    case row(Int)        // 0..<9
    case column(Int)     // 0..<9
    case box(Int)        // 0..<9, ordered left-to-right top-to-bottom

    /// All 81 (row,col) coordinates of this unit, in reading order.
    var cells: [(row: Int, col: Int)] {
        switch self {
        case .row(let r):
            return (0..<9).map { (r, $0) }
        case .column(let c):
            return (0..<9).map { ($0, c) }
        case .box(let b):
            let br = (b / 3) * 3, bc = (b % 3) * 3
            var out: [(Int, Int)] = []
            out.reserveCapacity(9)
            for r in br..<br+3 { for c in bc..<bc+3 { out.append((r, c)) } }
            return out
        }
    }

    /// Human-readable label, e.g. "row 3", "column B", "box 2".
    var label: String {
        switch self {
        case .row(let r): return "row \(r + 1)"
        case .column(let c): return "column \(c + 1)"
        case .box(let b): return "box \(b + 1)"
        }
    }

    static var all: [Unit] {
        (0..<9).map(Unit.row) + (0..<9).map(Unit.column) + (0..<9).map(Unit.box)
    }
}

/// Box index (0..8) for the cell at (row, col).
@inlinable func boxIndex(row: Int, col: Int) -> Int {
    (row / 3) * 3 + (col / 3)
}

/// Cells that share a row, column, or box with (row, col), excluding the cell itself.
func peers(of row: Int, _ col: Int) -> [(row: Int, col: Int)] {
    var out: [(Int, Int)] = []
    out.reserveCapacity(20)
    for c in 0..<9 where c != col { out.append((row, c)) }
    for r in 0..<9 where r != row { out.append((r, col)) }
    let br = (row / 3) * 3, bc = (col / 3) * 3
    for r in br..<br+3 {
        for c in bc..<bc+3 where !(r == row && c == col) && r != row && c != col {
            out.append((r, c))
        }
    }
    return out
}
