import Foundation

// MARK: - Pointing (box → row/column)

/// All candidate cells for digit `d` inside a box lie in the same row or column.
/// Therefore `d` cannot be placed in the rest of that row/column outside the box.
enum LockedCandidatesPointingDetector: TechniqueDetector {
    static let technique: TechniqueID = .lockedCandidatesPointing

    static func find(grid: [[Int]], candidates: CandidateGrid) -> LearningStep? {
        for b in 0..<9 {
            let box = Unit.box(b)
            let boxCells = box.cells
            for d in 1...9 {
                let positions = boxCells.filter { candidates.contains(d, row: $0.row, col: $0.col) }
                guard positions.count >= 2 else { continue }
                let rows = Set(positions.map { $0.row })
                let cols = Set(positions.map { $0.col })

                if rows.count == 1, let row = rows.first {
                    let line = Unit.row(row)
                    let outsideTargets = line.cells.filter { c in
                        boxIndex(row: c.row, col: c.col) != b &&
                        candidates.contains(d, row: c.row, col: c.col)
                    }
                    if outsideTargets.isEmpty { continue }
                    return makeStep(
                        digit: d,
                        boxUnit: box,
                        lineUnit: line,
                        boxPositions: positions,
                        targets: outsideTargets,
                        candidates: candidates
                    )
                }
                if cols.count == 1, let col = cols.first {
                    let line = Unit.column(col)
                    let outsideTargets = line.cells.filter { c in
                        boxIndex(row: c.row, col: c.col) != b &&
                        candidates.contains(d, row: c.row, col: c.col)
                    }
                    if outsideTargets.isEmpty { continue }
                    return makeStep(
                        digit: d,
                        boxUnit: box,
                        lineUnit: line,
                        boxPositions: positions,
                        targets: outsideTargets,
                        candidates: candidates
                    )
                }
            }
        }
        return nil
    }

    private static func makeStep(
        digit d: Int,
        boxUnit: Unit,
        lineUnit: Unit,
        boxPositions: [(row: Int, col: Int)],
        targets: [(row: Int, col: Int)],
        candidates: CandidateGrid
    ) -> LearningStep {
        var highlights: [HighlightedCell] = []
        for p in boxPositions {
            highlights.append(.init(row: p.row, col: p.col, role: .subject, digits: [d]))
        }
        for t in targets {
            highlights.append(.init(row: t.row, col: t.col, role: .target, digits: [d]))
        }

        let actions: [LearningAction] = targets.map { .eliminate(row: $0.row, col: $0.col, digit: d) }

        let explanation = """
        In **\(boxUnit.label)**, every candidate cell for digit **\(d)** lies in **\(lineUnit.label)**. \
        That means \(d) is locked into \(lineUnit.label) within this box — it must be placed at one of \
        those highlighted cells. So \(d) can be eliminated from every other cell in \(lineUnit.label) \
        that is outside this box.
        """

        return LearningStep(
            technique: .lockedCandidatesPointing,
            highlights: highlights,
            actions: actions,
            explanation: explanation,
            units: [boxUnit, lineUnit]
        )
    }
}

// MARK: - Claiming (row/column → box)

/// All candidate cells for digit `d` inside a row or column lie in a single box.
/// Therefore `d` can be eliminated from the rest of that box.
enum LockedCandidatesClaimingDetector: TechniqueDetector {
    static let technique: TechniqueID = .lockedCandidatesClaiming

    static func find(grid: [[Int]], candidates: CandidateGrid) -> LearningStep? {
        let lines: [Unit] = (0..<9).map(Unit.row) + (0..<9).map(Unit.column)
        for line in lines {
            for d in 1...9 {
                let positions = line.cells.filter { candidates.contains(d, row: $0.row, col: $0.col) }
                guard positions.count >= 2 else { continue }
                let boxes = Set(positions.map { boxIndex(row: $0.row, col: $0.col) })
                guard boxes.count == 1, let b = boxes.first else { continue }
                let box = Unit.box(b)
                let outsideTargets = box.cells.filter { c in
                    !((c.row == positions[0].row && line == Unit.row(c.row)) ||
                      (c.col == positions[0].col && line == Unit.column(c.col)))
                    && candidates.contains(d, row: c.row, col: c.col)
                    && !positions.contains(where: { $0.row == c.row && $0.col == c.col })
                }
                if outsideTargets.isEmpty { continue }

                var highlights: [HighlightedCell] = []
                for p in positions {
                    highlights.append(.init(row: p.row, col: p.col, role: .subject, digits: [d]))
                }
                for t in outsideTargets {
                    highlights.append(.init(row: t.row, col: t.col, role: .target, digits: [d]))
                }

                let actions: [LearningAction] = outsideTargets.map {
                    .eliminate(row: $0.row, col: $0.col, digit: d)
                }

                let explanation = """
                In **\(line.label)**, every empty cell that can still hold digit **\(d)** sits inside \
                **\(box.label)**. That means \(d) is claimed by this box from \(line.label)'s perspective: \
                wherever \(d) ends up in \(line.label), it has to be one of the highlighted cells inside \(box.label). \
                Therefore \(d) cannot appear anywhere else in \(box.label), and we can erase it from those cells.
                """

                return LearningStep(
                    technique: .lockedCandidatesClaiming,
                    highlights: highlights,
                    actions: actions,
                    explanation: explanation,
                    units: [line, box]
                )
            }
        }
        return nil
    }
}
