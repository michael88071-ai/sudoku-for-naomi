import XCTest
@testable import SudokuForNaomi

final class WalkthroughTests: XCTestCase {
    func test_starterLesson_solvesUsingSinglesOnly() {
        let lesson = LessonCatalog.lesson(id: "starter-singles")!
        let steps = LearningWalkthrough.generateSteps(puzzle: lesson.puzzle)
        XCTAssertGreaterThan(steps.count, 0)

        // Re-run, applying steps, and confirm the grid ends fully solved.
        var grid = lesson.puzzle
        var cands = CandidateGrid(from: grid)
        for step in steps {
            for action in step.actions {
                LearningWalkthrough.apply(action, grid: &grid, candidates: &cands)
            }
        }
        let isSolved = grid.allSatisfy { row in row.allSatisfy { $0 != 0 } }
        XCTAssertTrue(isSolved, "starter lesson should solve via the registered detectors")
    }

    func test_eachLessonProducesSomeSteps() {
        for lesson in LessonCatalog.lessons {
            let steps = LearningWalkthrough.generateSteps(puzzle: lesson.puzzle)
            XCTAssertGreaterThan(steps.count, 0, "lesson \(lesson.id) produced no steps")
        }
    }

    func test_techniqueLessonFinder_returnsExampleForEarlyTechniques() {
        // At a minimum, our curated lessons should cover singles.
        XCTAssertNotNil(TechniqueLessonFinder.firstExample(of: .nakedSingle))
        XCTAssertNotNil(TechniqueLessonFinder.firstExample(of: .hiddenSingle))
    }
}
