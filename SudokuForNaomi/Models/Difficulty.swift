import Foundation

enum Difficulty: String, CaseIterable, Codable, Hashable, Identifiable {
    case easy
    case medium
    case hard
    case extreme

    var id: String { rawValue }

    /// Approximate number of pre-filled cells (clues) in the generated puzzle.
    /// The generator may leave a few extra clues if removing more would break uniqueness.
    var targetClueCount: Int {
        switch self {
        case .easy: return 40
        case .medium: return 32
        case .hard: return 26
        case .extreme: return 22
        }
    }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .extreme: return "Extreme"
        }
    }

    var systemImageName: String {
        switch self {
        case .easy: return "sun.max"
        case .medium: return "cloud.sun"
        case .hard: return "bolt"
        case .extreme: return "flame.fill"
        }
    }

    /// True if puzzles for this difficulty must require techniques beyond simple
    /// singles to solve. The generator rejects candidates that the singles-only
    /// solver can finish, forcing the player to apply locked candidates / subsets / etc.
    var requiresAdvancedTechniques: Bool {
        switch self {
        case .easy, .medium, .hard: return false
        case .extreme: return true
        }
    }
}
