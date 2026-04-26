import SwiftUI
import SwiftData

@main
struct SudokuForNaomiApp: App {
    @State private var appearance = AppearanceSettings()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appearance)
        }
        .modelContainer(for: GameRecord.self)
    }
}
