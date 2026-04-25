import SwiftUI
import SwiftData

@main
struct SudokuForNaomiApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: GameRecord.self)
    }
}
