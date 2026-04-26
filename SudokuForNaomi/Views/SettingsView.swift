import SwiftUI

/// User-customizable appearance settings for the board: cell background, digit
/// color, and digit font size. Changes apply immediately and persist via
/// UserDefaults inside `AppearanceSettings`.
struct SettingsView: View {
    @Environment(AppearanceSettings.self) private var appearance

    var body: some View {
        @Bindable var appearance = appearance
        Form {
            Section("Colors") {
                ColorPicker("Background", selection: $appearance.backgroundColor, supportsOpacity: false)
                ColorPicker("Digits", selection: $appearance.textColor, supportsOpacity: false)
            }

            Section("Digit Size") {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(
                        value: $appearance.cellFontSize,
                        in: AppearanceSettings.minFontSize...AppearanceSettings.maxFontSize,
                        step: 1
                    )
                    HStack {
                        Text("\(Int(appearance.cellFontSize)) pt")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Sample")
                            .font(.system(size: appearance.cellFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(appearance.textColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(appearance.backgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                            )
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                preview
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            } header: {
                Text("Preview")
            }

            Section {
                Button(role: .destructive) {
                    appearance.resetToDefaults()
                } label: {
                    HStack {
                        Spacer()
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                        Spacer()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(appearance.backgroundColor.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Mini 3×3 board preview that mirrors the in-game cell rendering, so the
    /// user can see exactly how their choices will look on a real board.
    private var preview: some View {
        let demoValues = [
            [5, 0, 7],
            [0, 1, 0],
            [9, 0, 3],
        ]
        let givens: Set<SudokuBoard.Coord> = [
            .init(0, 0), .init(0, 2), .init(1, 1), .init(2, 0), .init(2, 2)
        ]
        return VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { c in
                        let value = demoValues[r][c]
                        let isGiven = givens.contains(.init(r, c))
                        ZStack {
                            appearance.backgroundColor
                            if value > 0 {
                                Text("\(value)")
                                    .font(.system(size: appearance.cellFontSize, weight: isGiven ? .bold : .medium, design: .rounded))
                                    .foregroundStyle(isGiven ? appearance.textColor : appearance.textColor.opacity(0.7))
                            }
                        }
                        .frame(width: 56, height: 56)
                        .overlay(Rectangle().stroke(Color.gray.opacity(0.5), lineWidth: 0.5))
                    }
                }
            }
        }
        .overlay(Rectangle().stroke(Color.primary, lineWidth: 1.5))
    }
}
