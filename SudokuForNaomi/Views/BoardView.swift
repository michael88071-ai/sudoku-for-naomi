import SwiftUI

struct BoardView: View {
    let viewModel: GameViewModel

    var body: some View {
        GeometryReader { geo in
            // Snap each cell to an integer point so all 9 columns/rows render the
            // exact same width — sub-pixel rounding combined with the thick box
            // dividers was making edge cells visually narrower than middle cells.
            let cellSide = floor(min(geo.size.width, geo.size.height) / 9)
            let side = cellSide * 9

            ZStack {
                // Cell grid
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { c in
                                CellView(viewModel: viewModel, row: r, col: c)
                                    .frame(width: cellSide, height: cellSide)
                            }
                        }
                    }
                }

                // Grid lines drawn on top so they're crisp regardless of cell content.
                gridLines(side: side, cellSide: cellSide)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Thin lines for every cell; thick lines every 3 cells for the 3×3 box separators.
    private func gridLines(side: CGFloat, cellSide: CGFloat) -> some View {
        Canvas { ctx, size in
            for i in 0...9 {
                let pos = CGFloat(i) * cellSide
                let isThick = i % 3 == 0
                let lineWidth: CGFloat = isThick ? 2.5 : 0.8
                // Always use a fixed dark gray (not `.primary`, which flips with
                // color scheme) so lines stay visible against the user's chosen
                // background. Default white background needs near-black box
                // dividers and a clearly-visible mid-gray for the thin grid.
                let color: Color = isThick ? Color.black.opacity(0.85) : Color.gray.opacity(0.7)

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
