import SwiftUI
import SwiftData

@main
struct SudokuForNaomiApp: App {
    @State private var appearance = AppearanceSettings()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appearance)
                // The default appearance is white background + black digits, and
                // every screen uses `.primary` / `.secondary` text colors. Those
                // semantic colors follow the system's color scheme, so on a
                // dark-mode device they'd render light → invisible on our white
                // background. Pin the app to light mode so the chrome (titles,
                // captions, gear icon, thick box lines, etc.) always pairs
                // correctly with the default light board.
                .preferredColorScheme(.light)
        }
        .modelContainer(for: GameRecord.self)
    }
}
