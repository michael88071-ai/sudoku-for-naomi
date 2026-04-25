import Foundation
import SwiftData

/// Persisted record of a finished game, shown on the History dashboard.
@Model
final class GameRecord {
    var id: UUID
    var startedAt: Date
    var endedAt: Date
    var difficultyRaw: String
    var statusRaw: String
    var elapsedSeconds: Int
    var mistakeCount: Int

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        difficulty: Difficulty,
        status: GameStatus,
        elapsedSeconds: Int,
        mistakeCount: Int
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.difficultyRaw = difficulty.rawValue
        self.statusRaw = status.rawValue
        self.elapsedSeconds = elapsedSeconds
        self.mistakeCount = mistakeCount
    }

    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .easy
    }

    var status: GameStatus {
        GameStatus(rawValue: statusRaw) ?? .quit
    }
}

enum GameStatus: String, Codable, CaseIterable {
    case won
    case quit
    case failed

    var displayName: String {
        switch self {
        case .won: return "Won"
        case .quit: return "Quit"
        case .failed: return "Failed"
        }
    }

    var systemImageName: String {
        switch self {
        case .won: return "checkmark.seal.fill"
        case .quit: return "xmark.circle"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}
