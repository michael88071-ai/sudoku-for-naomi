import Foundation

enum Difficulty: String, CaseIterable, Codable, Hashable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    /// Approximate number of pre-filled cells (clues) in the generated puzzle.
    /// The generator may leave a few extra clues if removing more would break uniqueness.
    var targetClueCount: Int {
        switch self {
        case .easy: return 40
        case .medium: return 32
        case .hard: return 26
        }
    }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var systemImageName: String {
        switch self {
        case .easy: return "sun.max"
        case .medium: return "cloud.sun"
        case .hard: return "bolt"
        }
    }
}
