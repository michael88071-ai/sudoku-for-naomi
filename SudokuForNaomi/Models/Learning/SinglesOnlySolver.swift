import Foundation

/// Tries to fully solve `puzzle` using only Full House / Naked Single / Hidden Single.
/// Returns true if singles alone are enough — i.e. the puzzle is "easy" by human standards.
/// The Extreme difficulty generator uses this as a filter: any puzzle the singles-only
/// solver finishes is rejected, ensuring the player must reach for locked candidates,
/// subsets, or harder techniques.
enum SinglesOnlySolver {
    private static let detectors: [any TechniqueDetector.Type] = [
        FullHouseDetector.self,
        NakedSingleDetector.self,
        HiddenSingleDetector.self,
    ]

    static func solves(_ puzzle: [[Int]]) -> Bool {
        var grid = puzzle
        var cands = CandidateGrid(from: grid)
        let maxIterations = 200
        for _ in 0..<maxIterations {
            if grid.allSatisfy({ row in row.allSatisfy { $0 != 0 } }) { return true }
            var step: LearningStep?
            for d in detectors {
                if let s = d.find(grid: grid, candidates: cands) { step = s; break }
            }
            guard let step else { return false }
            for action in step.actions {
                LearningWalkthrough.apply(action, grid: &grid, candidates: &cands)
            }
        }
        return false
    }
}
