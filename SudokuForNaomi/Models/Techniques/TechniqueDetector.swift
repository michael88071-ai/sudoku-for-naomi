import Foundation

/// Detects a single occurrence of a solving technique in the current grid state.
///
/// Implementations return at most one step per call (the first match in scan order).
/// The walkthrough engine repeatedly applies the cheapest detector that finds a step,
/// then re-scans, mimicking how a human would solve.
protocol TechniqueDetector {
    static var technique: TechniqueID { get }
    static func find(grid: [[Int]], candidates: CandidateGrid) -> LearningStep?
}

/// Convenience: list of detectors in priority order.
enum TechniqueRegistry {
    static let all: [any TechniqueDetector.Type] = [
        FullHouseDetector.self,
        NakedSingleDetector.self,
        HiddenSingleDetector.self,
        LockedCandidatesPointingDetector.self,
        LockedCandidatesClaimingDetector.self,
        NakedPairDetector.self,
        HiddenPairDetector.self,
    ]

    static func detector(for id: TechniqueID) -> (any TechniqueDetector.Type)? {
        all.first { $0.technique == id }
    }
}
