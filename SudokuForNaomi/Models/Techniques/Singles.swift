import Foundation

// MARK: - Full House

/// A unit (row, column, or box) has 8 cells filled. The single empty cell can
/// only hold the missing digit.
enum FullHouseDetector: TechniqueDetector {
    static let technique: TechniqueID = .fullHouse

    static func find(grid: [[Int]], candidates: CandidateGrid) -> LearningStep? {
        for unit in Unit.all {
            let cells = unit.cells
            let values = cells.map { grid[$0.row][$0.col] }
            let filled = values.filter { $0 != 0 }
            guard filled.count == 8 else { continue }
            guard let emptyIdx = values.firstIndex(of: 0) else { continue }
            let missing = Set(1...9).subtracting(filled).first!
            let target = cells[emptyIdx]

            var highlights: [HighlightedCell] = []
            for (i, c) in cells.enumerated() {
                if i == emptyIdx {
                    highlights.append(.init(row: c.row, col: c.col, role: .target, digits: [missing]))
                } else {
                    highlights.append(.init(row: c.row, col: c.col, role: .eliminator, digits: [grid[c.row][c.col]]))
                }
            }

            let explanation = """
            \(unit.label.capitalized) already has 8 of the 9 digits placed. \
            Only **\(missing)** is missing, and there is exactly one empty cell — \
            so it must hold \(missing).
            """

            return LearningStep(
                technique: technique,
                highlights: highlights,
                actions: [.place(row: target.row, col: target.col, digit: missing)],
                explanation: explanation,
                units: [unit]
            )
        }
        return nil
    }
}

// MARK: - Naked Single

/// A cell has only one possible digit left after eliminating peers.
enum NakedSingleDetector: TechniqueDetector {
    static let technique: TechniqueID = .nakedSingle

    static func find(grid: [[Int]], candidates: CandidateGrid) -> LearningStep? {
        for r in 0..<9 {
            for c in 0..<9 where grid[r][c] == 0 {
                guard candidates.count(row: r, col: c) == 1 else { continue }
                let d = candidates.candidates(row: r, col: c).first!

                // Highlight peers that already have d to make the elimination story visible.
                var highlights: [HighlightedCell] = [
                    .init(row: r, col: c, role: .target, digits: [d])
                ]
                for p in peers(of: r, c) where grid[p.row][p.col] == d {
                    highlights.append(.init(row: p.row, col: p.col, role: .eliminator, digits: [d]))
                }

                let explanation = """
                Look at the candidates for cell **(\(r + 1), \(c + 1))**. Every other digit \
                has been blocked by a peer in the same row, column, or box. \
                The only digit that is still legal here is **\(d)**, so it must be placed.
                """

                return LearningStep(
                    technique: technique,
                    highlights: highlights,
                    actions: [.place(row: r, col: c, digit: d)],
                    explanation: explanation,
                    units: []
                )
            }
        }
        return nil
    }
}

// MARK: - Hidden Single

/// Inside a unit, a digit has only one cell where it can still go — even if that
/// cell has multiple candidates.
enum HiddenSingleDetector: TechniqueDetector {
    static let technique: TechniqueID = .hiddenSingle

    static func find(grid: [[Int]], candidates: CandidateGrid) -> LearningStep? {
        for unit in Unit.all {
            let cells = unit.cells
            for d in 1...9 {
                var positions: [(row: Int, col: Int)] = []
                var alreadyPlaced = false
                for c in cells {
                    if grid[c.row][c.col] == d { alreadyPlaced = true; break }
                    if candidates.contains(d, row: c.row, col: c.col) {
                        positions.append(c)
                    }
                }
                if alreadyPlaced { continue }
                guard positions.count == 1 else { continue }
                let target = positions[0]
                // Skip if it's also a naked single — that detector handles it more directly.
                if candidates.count(row: target.row, col: target.col) == 1 { continue }

                var highlights: [HighlightedCell] = [
                    .init(row: target.row, col: target.col, role: .target, digits: [d])
                ]
                for c in cells where !(c.row == target.row && c.col == target.col) {
                    let role: HighlightedCell.Role = grid[c.row][c.col] == 0 ? .unit : .eliminator
                    let digits: Set<Int> = grid[c.row][c.col] == 0 ? [] : [grid[c.row][c.col]]
                    highlights.append(.init(row: c.row, col: c.col, role: role, digits: digits))
                }

                let explanation = """
                Scan \(unit.label) for digit **\(d)**. Every other empty cell in this unit \
                has \(d) eliminated by a peer (look at the surrounding row/column/box). \
                Only **(\(target.row + 1), \(target.col + 1))** can still hold \(d), so place it there.
                """

                return LearningStep(
                    technique: technique,
                    highlights: highlights,
                    actions: [.place(row: target.row, col: target.col, digit: d)],
                    explanation: explanation,
                    units: [unit]
                )
            }
        }
        return nil
    }
}
