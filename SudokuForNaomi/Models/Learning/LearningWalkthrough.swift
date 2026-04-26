import Foundation

/// Walks a partially-filled grid forward by repeatedly applying the cheapest
/// available technique. The result is the ordered list of teaching steps a learner
/// can step through.
struct LearningWalkthrough {
    /// Applies an action (place / eliminate) to the working state.
    static func apply(_ action: LearningAction, grid: inout [[Int]], candidates: inout CandidateGrid) {
        switch action {
        case .place(let r, let c, let d):
            grid[r][c] = d
            candidates.place(d, row: r, col: c)
        case .eliminate(let r, let c, let d):
            candidates.eliminate(d, row: r, col: c)
        }
    }

    /// Generates the full sequence of steps that solve `puzzle` using the registered
    /// detectors in priority order. Stops if no detector can find a step (the puzzle
    /// requires a technique we haven't taught yet) and returns the partial list.
    static func generateSteps(puzzle: [[Int]], detectors: [any TechniqueDetector.Type] = TechniqueRegistry.all) -> [LearningStep] {
        var grid = puzzle
        var candidates = CandidateGrid(from: grid)
        var steps: [LearningStep] = []

        let maxIterations = 200
        var iterations = 0
        while iterations < maxIterations {
            iterations += 1

            // Stop when solved.
            if grid.allSatisfy({ row in row.allSatisfy { $0 != 0 } }) { break }

            var found: LearningStep?
            for detector in detectors {
                if let step = detector.find(grid: grid, candidates: candidates) {
                    found = step
                    break
                }
            }
            guard let step = found else { break }
            steps.append(step)
            for action in step.actions {
                apply(action, grid: &grid, candidates: &candidates)
            }
        }

        return steps
    }

    /// Returns the next teaching step starting from the current state, or nil if none of
    /// the supplied detectors apply.
    static func nextStep(grid: [[Int]], candidates: CandidateGrid, detectors: [any TechniqueDetector.Type] = TechniqueRegistry.all) -> LearningStep? {
        for detector in detectors {
            if let step = detector.find(grid: grid, candidates: candidates) {
                return step
            }
        }
        return nil
    }
}
