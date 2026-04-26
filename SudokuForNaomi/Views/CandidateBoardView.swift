import SwiftUI

/// 9×9 board for Learning Mode. Renders pencil marks, applies role-based
/// highlighting from the current step, and overlays the box grid lines.
struct CandidateBoardView: View {
    let grid: [[Int]]
    let givens: [[Bool]]
    let candidates: CandidateGrid
    let step: LearningStep?

    var body: some View {
        let lookup = highlightLookup(step?.highlights ?? [])
        let placementCells = placementSet(step?.actions ?? [])
        let eliminationCells = eliminationSet(step?.actions ?? [])

        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cellSide = side / 9

            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { c in
                                let highlight = lookup[Coord(r, c)]
                                CandidateCellView(
                                    value: grid[r][c],
                                    isGiven: givens[r][c],
                                    candidates: candidates.candidates(row: r, col: c),
                                    role: highlight?.role,
                                    emphasizedDigits: highlight?.digits ?? [],
                                    isEliminationTarget: eliminationCells.contains(Coord(r, c)),
                                    isPlacement: placementCells.contains(Coord(r, c))
                                )
                                .frame(width: cellSide, height: cellSide)
                            }
                        }
                    }
                }
                gridLines(side: side, cellSide: cellSide)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private struct Coord: Hashable { let r: Int; let c: Int; init(_ r: Int, _ c: Int) { self.r = r; self.c = c } }

    private func highlightLookup(_ highlights: [HighlightedCell]) -> [Coord: HighlightedCell] {
        var out: [Coord: HighlightedCell] = [:]
        // If a cell appears multiple times, prefer the more "important" role
        // (target > subject > eliminator > unit).
        let priority: [HighlightedCell.Role: Int] = [.target: 4, .subject: 3, .eliminator: 2, .unit: 1]
        for h in highlights {
            let key = Coord(h.row, h.col)
            if let existing = out[key], (priority[existing.role] ?? 0) >= (priority[h.role] ?? 0) {
                continue
            }
            out[key] = h
        }
        return out
    }

    private func placementSet(_ actions: [LearningAction]) -> Set<Coord> {
        var out: Set<Coord> = []
        for a in actions { if case let .place(r, c, _) = a { out.insert(Coord(r, c)) } }
        return out
    }

    private func eliminationSet(_ actions: [LearningAction]) -> Set<Coord> {
        var out: Set<Coord> = []
        for a in actions { if case let .eliminate(r, c, _) = a { out.insert(Coord(r, c)) } }
        return out
    }

    private func gridLines(side: CGFloat, cellSide: CGFloat) -> some View {
        Canvas { ctx, size in
            for i in 0...9 {
                let pos = CGFloat(i) * cellSide
                let isThick = i % 3 == 0
                let lineWidth: CGFloat = isThick ? 2.5 : 0.5
                let color: Color = isThick ? .primary : .gray.opacity(0.55)
                let vertical = Path { p in
                    p.move(to: CGPoint(x: pos, y: 0))
                    p.addLine(to: CGPoint(x: pos, y: size.height))
                }
                let horizontal = Path { p in
                    p.move(to: CGPoint(x: 0, y: pos))
                    p.addLine(to: CGPoint(x: size.width, y: pos))
                }
                ctx.stroke(vertical, with: .color(color), lineWidth: lineWidth)
                ctx.stroke(horizontal, with: .color(color), lineWidth: lineWidth)
            }
        }
        .allowsHitTesting(false)
    }
}
