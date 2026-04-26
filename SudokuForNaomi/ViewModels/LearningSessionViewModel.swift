import Foundation

/// Drives a learning lesson: holds the current grid + candidates, exposes the
/// next teaching step, and applies it on user request.
@MainActor
@Observable
final class LearningSessionViewModel {
    let lesson: Lesson
    private(set) var grid: [[Int]]
    private(set) var candidates: CandidateGrid
    private(set) var history: [LearningStep] = []
    private(set) var currentStep: LearningStep?
    /// True if we ran out of techniques before finishing — i.e. the puzzle needs
    /// a strategy not yet implemented in this app.
    private(set) var stuck: Bool = false
    /// True when the grid is fully solved.
    var isSolved: Bool { grid.allSatisfy { row in row.allSatisfy { $0 != 0 } } }

    init(lesson: Lesson) {
        self.lesson = lesson
        self.grid = lesson.puzzle
        self.candidates = CandidateGrid(from: lesson.puzzle)
        recomputeNextStep()
    }

    /// Apply the current step's actions and advance to the next.
    func applyCurrentStep() {
        guard let step = currentStep else { return }
        for action in step.actions {
            LearningWalkthrough.apply(action, grid: &grid, candidates: &candidates)
        }
        history.append(step)
        recomputeNextStep()
    }

    /// Restart the lesson from the original puzzle.
    func restart() {
        grid = lesson.puzzle
        candidates = CandidateGrid(from: lesson.puzzle)
        history = []
        stuck = false
        recomputeNextStep()
    }

    private func recomputeNextStep() {
        if isSolved { currentStep = nil; stuck = false; return }
        if let step = LearningWalkthrough.nextStep(grid: grid, candidates: candidates) {
            currentStep = step
            stuck = false
        } else {
            currentStep = nil
            stuck = true
        }
    }
}

/// Helpers for the technique picker — find the first lesson + step that
/// demonstrates a given technique.
enum TechniqueLessonFinder {
    struct Found {
        let lesson: Lesson
        /// Number of steps to apply before the example step shows up.
        let stepsToSkip: Int
        let exampleStep: LearningStep
    }

    /// Walks every curated lesson; returns the first encounter of `technique`.
    static func firstExample(of technique: TechniqueID, in lessons: [Lesson] = LessonCatalog.lessons) -> Found? {
        for lesson in lessons {
            var grid = lesson.puzzle
            var candidates = CandidateGrid(from: grid)
            var skipped = 0
            let maxIterations = 200
            for _ in 0..<maxIterations {
                guard let step = LearningWalkthrough.nextStep(grid: grid, candidates: candidates) else { break }
                if step.technique == technique {
                    return Found(lesson: lesson, stepsToSkip: skipped, exampleStep: step)
                }
                for action in step.actions {
                    LearningWalkthrough.apply(action, grid: &grid, candidates: &candidates)
                }
                skipped += 1
            }
        }
        return nil
    }
}
