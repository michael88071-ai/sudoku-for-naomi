import Foundation

// MARK: - Naked Pair

/// Two cells in a unit share the same exact pair of candidates. Those two digits
/// must occupy those two cells (in some order), so they can be eliminated from
/// every other cell in the unit.
enum NakedPairDetector: TechniqueDetector {
    static let technique: TechniqueID = .nakedPair

    static func find(grid: [[Int]], candidates: CandidateGrid) -> LearningStep? {
        for unit in Unit.all {
            let cells = unit.cells.filter { grid[$0.row][$0.col] == 0 }
            // Find pairs of cells whose candidate sets are identical with size 2.
            for i in 0..<cells.count {
                let a = cells[i]
                guard candidates.count(row: a.row, col: a.col) == 2 else { continue }
                let pairMask = candidates.mask(row: a.row, col: a.col)
                for j in (i+1)..<cells.count {
                    let b = cells[j]
                    guard candidates.mask(row: b.row, col: b.col) == pairMask else { continue }
                    let pairDigits = candidates.candidates(row: a.row, col: a.col)

                    // Find eliminations among the other cells in this unit.
                    var targets: [(cell: (row: Int, col: Int), digits: Set<Int>)] = []
                    for c in cells where !(c.row == a.row && c.col == a.col) && !(c.row == b.row && c.col == b.col) {
                        let removable = pairDigits.filter { candidates.contains($0, row: c.row, col: c.col) }
                        if !removable.isEmpty {
                            targets.append((c, removable))
                        }
                    }
                    if targets.isEmpty { continue }

                    var highlights: [HighlightedCell] = [
                        .init(row: a.row, col: a.col, role: .subject, digits: pairDigits),
                        .init(row: b.row, col: b.col, role: .subject, digits: pairDigits),
                    ]
                    var actions: [LearningAction] = []
                    for t in targets {
                        highlights.append(.init(row: t.cell.row, col: t.cell.col, role: .target, digits: t.digits))
                        for d in t.digits.sorted() {
                            actions.append(.eliminate(row: t.cell.row, col: t.cell.col, digit: d))
                        }
                    }

                    let pairList = pairDigits.sorted().map(String.init).joined(separator: " and ")
                    let explanation = """
                    Cells **(\(a.row + 1), \(a.col + 1))** and **(\(b.row + 1), \(b.col + 1))** in \
                    \(unit.label) both have candidates **{\(pairList)}** — and nothing else. \
                    Whichever way \(pairDigits.sorted().first!) and \(pairDigits.sorted().last!) end up, they have \
                    to occupy these two cells. So neither digit can appear anywhere else in \(unit.label), \
                    and the other candidates highlighted in red can be removed.
                    """

                    return LearningStep(
                        technique: technique,
                        highlights: highlights,
                        actions: actions,
                        explanation: explanation,
                        units: [unit]
                    )
                }
            }
        }
        return nil
    }
}

// MARK: - Hidden Pair

/// Two digits each appear as candidates in only the same two cells of a unit.
/// Those cells must hold those two digits, so any other candidates inside them
/// can be eliminated.
enum HiddenPairDetector: TechniqueDetector {
    static let technique: TechniqueID = .hiddenPair

    static func find(grid: [[Int]], candidates: CandidateGrid) -> LearningStep? {
        for unit in Unit.all {
            let cells = unit.cells

            // For each digit, list the empty cells in this unit that still allow it.
            var positions: [Int: [(row: Int, col: Int)]] = [:]
            for d in 1...9 {
                var alreadyPlaced = false
                var spots: [(Int, Int)] = []
                for c in cells {
                    if grid[c.row][c.col] == d { alreadyPlaced = true; break }
                    if candidates.contains(d, row: c.row, col: c.col) { spots.append(c) }
                }
                if alreadyPlaced { continue }
                positions[d] = spots
            }

            let pairCandidates = positions.filter { $0.value.count == 2 }.keys.sorted()
            for i in 0..<pairCandidates.count {
                for j in (i+1)..<pairCandidates.count {
                    let d1 = pairCandidates[i], d2 = pairCandidates[j]
                    let s1 = positions[d1]!
                    let s2 = positions[d2]!
                    let set1 = Set(s1.map { Coord($0.row, $0.col) })
                    let set2 = Set(s2.map { Coord($0.row, $0.col) })
                    guard set1 == set2 else { continue }

                    let pairCells = s1
                    let pairDigits: Set<Int> = [d1, d2]

                    // The hidden pair only "bites" if at least one of the two cells has extra candidates.
                    var targets: [(cell: (row: Int, col: Int), digits: Set<Int>)] = []
                    for c in pairCells {
                        let extras = candidates.candidates(row: c.row, col: c.col).subtracting(pairDigits)
                        if !extras.isEmpty {
                            targets.append((c, extras))
                        }
                    }
                    if targets.isEmpty { continue }

                    var highlights: [HighlightedCell] = []
                    for c in pairCells {
                        highlights.append(.init(row: c.row, col: c.col, role: .subject, digits: pairDigits))
                    }
                    var actions: [LearningAction] = []
                    for t in targets {
                        highlights.append(.init(row: t.cell.row, col: t.cell.col, role: .target, digits: t.digits))
                        for d in t.digits.sorted() {
                            actions.append(.eliminate(row: t.cell.row, col: t.cell.col, digit: d))
                        }
                    }

                    let cellList = pairCells.map { "(\($0.row + 1), \($0.col + 1))" }.joined(separator: " and ")
                    let explanation = """
                    Inside \(unit.label), digits **\(d1)** and **\(d2)** both appear as candidates in only \
                    the two cells \(cellList). Since two digits need two cells, those cells must hold \
                    \(d1) and \(d2) (in some order). All other candidates highlighted in red can be removed \
                    from those cells.
                    """

                    return LearningStep(
                        technique: technique,
                        highlights: highlights,
                        actions: actions,
                        explanation: explanation,
                        units: [unit]
                    )
                }
            }
        }
        return nil
    }

    private struct Coord: Hashable {
        let r: Int; let c: Int
        init(_ r: Int, _ c: Int) { self.r = r; self.c = c }
    }
}
