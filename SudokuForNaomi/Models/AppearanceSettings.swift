import SwiftUI

/// User-tunable visual settings for the board: cell background, digit color, and
/// digit font size. Persisted via UserDefaults so changes survive relaunch.
///
/// Defaults are intentionally pinned to a high-contrast white background with
/// black digits regardless of system light/dark mode — that's the look the
/// product owner asked for. Users can still customize via the Settings screen.
@MainActor
@Observable
final class AppearanceSettings {
    static let defaultBackground: Color = .white
    static let defaultText: Color = .black
    static let defaultFontSize: Double = 24
    static let minFontSize: Double = 16
    static let maxFontSize: Double = 36

    var backgroundColor: Color { didSet { persist() } }
    var textColor: Color { didSet { persist() } }
    var cellFontSize: Double { didSet { persist() } }

    private let store: UserDefaults

    init(store: UserDefaults = .standard) {
        self.store = store
        self.backgroundColor = Self.loadColor(prefix: Keys.backgroundPrefix, store: store) ?? Self.defaultBackground
        self.textColor = Self.loadColor(prefix: Keys.textPrefix, store: store) ?? Self.defaultText
        let saved = store.double(forKey: Keys.fontSize)
        self.cellFontSize = saved == 0 ? Self.defaultFontSize : saved
    }

    /// Reset every preference back to the product default.
    func resetToDefaults() {
        backgroundColor = Self.defaultBackground
        textColor = Self.defaultText
        cellFontSize = Self.defaultFontSize
    }

    // MARK: - Persistence

    private enum Keys {
        static let backgroundPrefix = "appearance.bg"
        static let textPrefix = "appearance.fg"
        static let fontSize = "appearance.fontSize"
    }

    private func persist() {
        Self.saveColor(backgroundColor, prefix: Keys.backgroundPrefix, store: store)
        Self.saveColor(textColor, prefix: Keys.textPrefix, store: store)
        store.set(cellFontSize, forKey: Keys.fontSize)
    }

    private static func saveColor(_ color: Color, prefix: String, store: UserDefaults) {
        let rgba = color.rgbaComponents()
        store.set(rgba.r, forKey: "\(prefix).r")
        store.set(rgba.g, forKey: "\(prefix).g")
        store.set(rgba.b, forKey: "\(prefix).b")
        store.set(rgba.a, forKey: "\(prefix).a")
    }

    private static func loadColor(prefix: String, store: UserDefaults) -> Color? {
        // Treat missing alpha as "no value stored" — fresh installs get the default.
        guard store.object(forKey: "\(prefix).a") != nil else { return nil }
        let r = store.double(forKey: "\(prefix).r")
        let g = store.double(forKey: "\(prefix).g")
        let b = store.double(forKey: "\(prefix).b")
        let a = store.double(forKey: "\(prefix).a")
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

extension Color {
    /// Decompose into sRGB components. Falls back to (1,1,1,1) if the color
    /// can't be resolved (which shouldn't happen for the literals we support).
    func rgbaComponents() -> (r: Double, g: Double, b: Double, a: Double) {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (Double(r), Double(g), Double(b), Double(a))
        }
        #endif
        return (1, 1, 1, 1)
    }
}
