import Foundation

/// A curated puzzle used to teach techniques. The walkthrough engine produces
/// the step list at runtime — we just need the starting position.
struct Lesson: Identifiable, Hashable {
    let id: String
    let title: String
    let blurb: String
    let puzzle: [[Int]]
}

enum LessonCatalog {
    /// 9-row puzzle from a single "..." string of 81 chars (0/. = empty).
    private static func parse(_ s: String) -> [[Int]] {
        let chars = Array(s.filter { $0.isNumber || $0 == "." })
        precondition(chars.count == 81, "puzzle must be 81 chars, got \(chars.count)")
        var grid: [[Int]] = []
        grid.reserveCapacity(9)
        for r in 0..<9 {
            var row: [Int] = []
            row.reserveCapacity(9)
            for c in 0..<9 {
                let ch = chars[r * 9 + c]
                row.append(ch == "." ? 0 : Int(String(ch))!)
            }
            grid.append(row)
        }
        return grid
    }

    /// Hand-picked puzzles. Ordered easy → hard. The walkthrough engine derives
    /// every teaching step from these.
    static let lessons: [Lesson] = [
        Lesson(
            id: "starter-singles",
            title: "Starter — Singles Practice",
            blurb: "A gentle puzzle that solves with full houses and naked/hidden singles only.",
            puzzle: parse(
                "530070000" +
                "600195000" +
                "098000060" +
                "800060003" +
                "400803001" +
                "700020006" +
                "060000280" +
                "000419005" +
                "000080079"
            )
        ),
        Lesson(
            id: "locked-candidates",
            title: "Locked Candidates",
            blurb: "Practice spotting digits that get pinned to a row or column inside one box.",
            puzzle: parse(
                "984000000" +
                "000000700" +
                "000700804" +
                "200005400" +
                "060000010" +
                "001300006" +
                "405002000" +
                "002000000" +
                "000000571"
            )
        ),
        Lesson(
            id: "naked-and-hidden-pairs",
            title: "Naked & Hidden Pairs",
            blurb: "A medium puzzle that needs subset reasoning beyond simple singles.",
            puzzle: parse(
                "400000938" +
                "032094156" +
                "695300240" +
                "150000004" +
                "069000023" +
                "000050000" +
                "010536420" +
                "086470391" +
                "000010085"
            )
        ),
    ]

    static func lesson(id: String) -> Lesson? { lessons.first { $0.id == id } }
}
