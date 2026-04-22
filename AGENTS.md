# Repository Guidelines

## Project Structure & Module Organization
`ewbapp/` contains the iOS app target. Key folders are `Views/` for SwiftUI screens, `ViewModels/` for presentation state, `Services/` for auth, sync, map, and API integrations, `Repositories/` for data access, `Models/` for enums/DTOs/domain types, `CoreData/` for persistence, `Config/` for app settings, and `Resources/` plus `Assets.xcassets/` for bundled content. Tests live in `ewbappTests/` and `LamaLamaRangersTests/`, with `UnitTests/` and `UITests/` subfolders where present.

## Build, Test, and Development Commands
Use Xcode for day-to-day development, or run from the repo root:

```sh
xcodebuild -project ewbapp.xcodeproj -scheme ewbapp -destination 'generic/platform=iOS' build
xcodebuild -project ewbapp.xcodeproj -scheme ewbapp -destination 'platform=iOS Simulator,name=iPhone 16' test
```

The first command builds the app target. The second runs XCTest suites on a simulator. If simulator services are unavailable in your shell session, run the same actions from Xcode instead.

## Coding Style & Naming Conventions
Follow standard Swift style: 4-space indentation, one top-level type per file, `UpperCamelCase` for types, `lowerCamelCase` for properties and functions. Name SwiftUI screens with a `View` suffix (`MapView.swift`), view models with `ViewModel`, and tests with `Tests`. Keep feature code grouped by domain folder rather than by file type when extending an existing area.

## Testing Guidelines
This repository uses `XCTest` for unit and UI coverage. Add unit tests beside the relevant target under `ewbappTests/` or `LamaLamaRangersTests/UnitTests/`; add UI flows under `UITests/`. Name test files after the subject under test, for example `SyncQueueManagerTests.swift`, and prefer descriptive methods such as `testEqualTimestampsUseDeterministicTiebreaker()`.

## Commit & Pull Request Guidelines
Recent history follows Conventional Commit style: `feat(scope): ...`, `fix(scope): ...`, `chore: ...`. Keep subjects imperative and scoped to the affected area, for example `fix(sync): guard against double start`. PRs should include a short summary, linked task or issue, test notes, and screenshots for SwiftUI changes that affect visible flows.

## Configuration & Safety Notes
Do not commit secrets or environment-specific credentials. Treat Core Data schema changes, sync logic, and location/privacy settings in `Info.plist` as high-risk edits and document them clearly in the PR.
