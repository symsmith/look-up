# Tasks

Each task lists the files it owns. Two tasks never own the same file.

| ID | Task | Owns | Blocked by |
|----|------|------|------------|
| T0 | Scaffold: git, `Package.swift`, shared Core types (`BreakSettings`, `PauseReason`, `ActivityDetecting`), `SettingsStore` + tests, placeholder app entry | `Package.swift`, `.gitignore`, `Sources/LookUpCore/BreakSettings.swift`, `Sources/LookUpCore/PauseReason.swift`, `Sources/LookUpCore/SettingsStore.swift`, `Tests/LookUpCoreTests/SettingsStoreTests.swift` | — |
| T1 | `BreakScheduler` state machine + tests | `Sources/LookUpCore/BreakScheduler.swift`, `Tests/LookUpCoreTests/BreakSchedulerTests.swift` | T0 |
| T2 | `Breathing` curve + tests; overlay windows and SwiftUI break view | `Sources/LookUpCore/Breathing.swift`, `Tests/LookUpCoreTests/BreathingTests.swift`, `Sources/LookUp/Overlay/*` | T0 |
| T3 | `ActivityClassifier` + tests; `SystemActivityMonitor` (IOKit assertions, CoreAudio mic, CoreMediaIO camera) | `Sources/LookUpCore/ActivityClassifier.swift`, `Tests/LookUpCoreTests/ActivityClassifierTests.swift`, `Sources/LookUp/Activity/*` | T0 |
| T4 | `AppModel`, settings panel, app entry | `Sources/LookUpCore/DisplayText.swift`, `Tests/LookUpCoreTests/DisplayTextTests.swift`, `Sources/LookUp/LookUpApp.swift`, `Sources/LookUp/AppModel.swift`, `Sources/LookUp/SettingsPanel.swift`, `Tests/LookUpCoreTests/BreakSettingsTests.swift` | T0 (code), T1+T2+T3 (compile) |
| T5 | App bundling: `Info.plist`, build script, `Makefile`, `README.md` with manual test steps | `Resources/Info.plist`, `scripts/build-app.sh`, `Makefile`, `README.md` | T0 |
| T6 | Merge, full build, test run, launch, verify overlay and pause detection | — | T1–T5 |

T1, T2, T3 run in parallel (separate worktrees). T4 and T5 run in the main checkout at the same time.
