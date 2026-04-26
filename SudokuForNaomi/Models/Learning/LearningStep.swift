import Foundation

/// Catalog of solving techniques the app can teach. Ordered roughly by difficulty
/// so the walkthrough engine can prefer simpler techniques first.
enum TechniqueID: String, CaseIterable, Identifiable, Hashable {
    case fullHouse
    case nakedSingle
    case hiddenSingle
    case lockedCandidatesPointing
    case lockedCandidatesClaiming
    case nakedPair
    case hiddenPair

    var id: String { rawValue }

    /// User-facing name.
    var displayName: String {
        switch self {
        case .fullHouse: return "Full House"
        case .nakedSingle: return "Naked Single"
        case .hiddenSingle: return "Hidden Single"
        case .lockedCandidatesPointing: return "Locked Candidates (Pointing)"
        case .lockedCandidatesClaiming: return "Locked Candidates (Claiming)"
        case .nakedPair: return "Naked Pair"
        case .hiddenPair: return "Hidden Pair"
        }
    }

    /// One-paragraph definition shown on the technique picker.
    var summary: String {
        switch self {
        case .fullHouse:
            return "A row, column, or box has eight digits placed. The single empty cell can only hold the missing digit."
        case .nakedSingle:
            return "A cell has just one candidate left. That digit must go there."
        case .hiddenSingle:
            return "Inside a unit, only one cell can still hold a particular digit — even if that cell has other candidates."
        case .lockedCandidatesPointing:
            return "All candidates for a digit inside a box lie in one row or column. That digit can be eliminated from the rest of the row/column outside the box."
        case .lockedCandidatesClaiming:
            return "All candidates for a digit inside a row or column lie in a single box. That digit can be eliminated from the rest of the box."
        case .nakedPair:
            return "Two cells in a unit share the same two candidates. Those digits can be removed from every other cell in the unit."
        case .hiddenPair:
            return "Two digits each appear as candidates in only the same two cells of a unit. Those cells must hold those two digits, so other candidates can be cleared."
        }
    }

    /// Difficulty tier (lower = easier). Used to order detectors.
    var priority: Int {
        switch self {
        case .fullHouse: return 0
        case .nakedSingle: return 1
        case .hiddenSingle: return 2
        case .lockedCandidatesPointing: return 3
        case .lockedCandidatesClaiming: return 4
        case .nakedPair: return 5
        case .hiddenPair: return 6
        }
    }
}

/// One actionable step the walkthrough can present to the learner.
struct LearningStep: Equatable {
    let technique: TechniqueID
    /// Cells that should be visually emphasized, in roles.
    let highlights: [HighlightedCell]
    /// What the step concludes — typically placing a digit or eliminating candidates.
    let actions: [LearningAction]
    /// User-facing explanation. Short paragraphs that read top to bottom.
    let explanation: String
    /// Unit(s) the technique was found in (e.g. row 3, box 5). Used in the explanation header.
    let units: [Unit]
}

struct HighlightedCell: Equatable, Hashable {
    enum Role: Equatable, Hashable {
        /// The cell where the action lands (digit placed or candidate removed).
        case target
        /// Cell whose candidates form the technique pattern (e.g. the two cells of a naked pair).
        case subject
        /// Cell whose presence drives an elimination (e.g. givens that already block a row).
        case eliminator
        /// Background context — the unit we're reasoning about.
        case unit
    }
    let row: Int
    let col: Int
    let role: Role
    /// Optional candidate digits to visually emphasize within this cell.
    let digits: Set<Int>

    init(row: Int, col: Int, role: Role, digits: Set<Int> = []) {
        self.row = row
        self.col = col
        self.role = role
        self.digits = digits
    }
}

enum LearningAction: Equatable, Hashable {
    case place(row: Int, col: Int, digit: Int)
    case eliminate(row: Int, col: Int, digit: Int)
}
