# SudokuForNaomi

A native iOS Sudoku game.

## Features
- Generate random valid Sudoku puzzles
- Three difficulty levels (Easy / Medium / Hard)
- Live mistake warnings as you play
- Per-game timer
- Quit / reset / mark-as-failed controls
- History dashboard tracking final status (won / quit / failed) and time

## Stack
- SwiftUI for the UI
- SwiftData for game-history persistence
- Pure-Swift Sudoku generator + backtracking solver, fully unit-tested
- iOS 17+ deployment target
- Project file is generated from [`project.yml`](project.yml) via [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `.xcodeproj` is git-ignored

## Building from a fresh clone

```bash
# Prerequisites: Xcode (with license accepted) and Homebrew
brew install xcodegen
cd sudoku_for_naomi
xcodegen generate
open SudokuForNaomi.xcodeproj
# In Xcode: ⌘R to run
```

## Repo layout
```
SudokuForNaomi/
├── App/            # @main entry + root navigation
├── Models/         # Pure-Swift game logic + SwiftData models
├── ViewModels/     # @Observable game state
├── Views/          # SwiftUI screens
└── Resources/      # Assets

SudokuForNaomiTests/  # XCTest unit tests for game logic
```

