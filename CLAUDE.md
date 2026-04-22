# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

iOS app for Yintjingga Aboriginal Corporation (YAC). Lama Lama Rangers track Lantana camara infestations around Port Stewart, Cape York, QLD. The active demo branch is **`demov3`** — a fully functional offline app with local-only persistence, Bluetooth mesh sync (MultipeerConnectivity), 5-tab UI, and 12 new field-safety and data-quality features added on top of `demov2`. No cloud backend is implemented (Supabase cloud sync is a simulated demo only).

## Build command

```bash
xcodebuild -scheme ewbapp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build
```

No test target exists. There is no linter configured.

## Project identifiers

- **Bundle ID:** `com.immanuel.ewbapp`
- **Xcode project:** `ewbapp.xcodeproj` (source root: `ewbapp/`)
- **iOS target:** 26.2
- **Git remote:** `https://github.com/username11384/ewbrangerapp.git`

## Critical Xcode project constraints

- **`PBXFileSystemSynchronizedRootGroup`** — never edit `.pbxproj` manually. Every `.swift` file on disk is auto-included in the target.
- **`SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`** — any file using `@Published`, `ObservableObject`, `Combine` operators, or `Timer` must have `import Combine` explicitly. The compiler will error without it.
- **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** — all types are `@MainActor` by default. Actor-isolated types (`SyncEngine`, `MeshSyncEngine`) must be declared `actor` explicitly or they'll pick up MainActor isolation unintentionally.

## Architecture

MVVM + Repository. The dependency graph flows strictly downward:

```
SwiftUI Views
  └── ViewModels  (@MainActor ObservableObject, @StateObject in views)
        └── Repositories  (sync CoreData reads, async writes)
              └── PersistenceController  (NSPersistentContainer)
                    ├── mainContext    — UI reads only
                    └── backgroundContext — all writes (shared lazy instance)
```

**`AppEnvironment`** (`AppEnvironment.swift`) is the DI root — a `@MainActor ObservableObject` singleton (`AppEnvironment.shared`) holding `persistence`, `syncEngine`, `locationManager`, and `authManager`. It is injected via `.environmentObject()` at the root and accessed via `@EnvironmentObject` in views, or directly as `AppEnvironment.shared` inside `init()` of `@StateObject` ViewModels (because `@EnvironmentObject` is not available during `init`).

## CoreData

- Model: `CoreData/LamaLamaRangers.xcdatamodeld`
- **No Xcode codegen** — all `NSManagedObject` subclasses are hand-written in `CoreData/ManagedObjects.swift`. Add new entities there and in the `.xcdatamodeld` file.
- Helper methods `context.fetchFirst(_:predicate:)` and `context.fetchAll(_:predicate:sortDescriptors:)` are in `CoreData/CoreDataHelpers.swift`.
- `backgroundContext` uses `NSMergeByPropertyObjectTrumpMergePolicy`; `mainContext` uses `NSMergeByPropertyStoreTrumpMergePolicy`.
- After any background save, wait ~150 ms before calling `load()` on a ViewModel — `automaticallyMergesChangesFromParent` fires asynchronously.

**Entities and key relationships:**

| Entity | Key relationships |
|---|---|
| `SightingLog` | `→ RangerProfile`, `→ InfestationZone` (optional), `↔ TreatmentRecord` (to-many) |
| `TreatmentRecord` | `→ SightingLog`, `→ RangerProfile`, `→ RangerTask` (followUpTask, optional) |
| `RangerTask` | `→ RangerProfile`, `→ TreatmentRecord` (sourceTreatment, optional) |
| `InfestationZone` | `↔ InfestationZoneSnapshot` (ordered, to-many), `↔ SightingLog` (to-many) |
| `InfestationZoneSnapshot` | `polygonCoordinates` stored as `NSArray` of `[[Double]]` (lat/lon pairs) |
| `PatrolRecord` | `→ RangerProfile`, `checklistItems` stored as `NSData` (JSON-encoded `[PatrolChecklistItem]`) |
| `PesticideStock` | `↔ PesticideUsageRecord` (to-many) |
| `SyncQueue` | Created atomically with entity saves via `SyncQueueManager.enqueue(...)` |
| `Equipment` | `↔ MaintenanceRecord` (to-many via `maintenanceRecords`) |
| `MaintenanceRecord` | `→ Equipment` |
| `SafetyCheckIn` | Standalone (no relationships) — stores interval, last check-in time, isActive |
| `HazardLog` | Standalone — GPS coords, hazardType, severity, photoPath, syncedToCloud |

`InfestationZone.snapshots` is `NSOrderedSet?` — access as `zone.snapshots?.array as? [InfestationZoneSnapshot]`, not `as? [...]` directly.

## Auth

Single shared PIN stored as a hash in Keychain (`KeychainService`). First login with any PIN sets it for all rangers. Demo PIN: `1234`. Rangers seeded on first launch: Alice Johnson (Senior Ranger), Bob Smith (Ranger), Carol White (Ranger). `AuthManager.changePIN(oldPIN:newPIN:)` validates the old hash before updating.

## Sync

- **Cloud sync (V3 — not implemented):** `SyncEngine.triggerSync()` is a no-op. `SyncQueue` entries accumulate but are never uploaded. Do not add real API calls or Supabase integration — that is V3 scope with no ETA.
- **Mesh sync (V2 — implemented):** `MeshSyncEngine` (Swift `actor`) uses `MultipeerConnectivity`, service type `"yac-lantana"`. Flow: connect → exchange manifest (`[ManifestEntry]`) → request diff IDs → `sendRequestedRecords` serialises SightingLog/TreatmentRecord/RangerTask as JSON → `receiveRecords` applies LWW by `updatedAt`. Photos are excluded from mesh sync.
- `SyncEngine` monitors connectivity via `NWPathMonitor` and calls `triggerSync()` on reconnect (no-op until V3).

## Map

- `MapView` is `UIViewRepresentable` wrapping `MKMapView`. Callbacks pass a `CGPoint` screen-space anchor alongside the tapped object so `MapActionCard` can position itself near the pin.
- Zone overlays: `ZonePolygonOverlay: MKPolygon` when a snapshot exists; `ZoneCircleOverlay: MKCircle` fallback derived from sighting centroid.
- Draw mode in `MapContainerView`: user taps vertices → `drawVertices: [CLLocationCoordinate2D]` → `ZoneRepository.addSnapshot(...)`.
- Polygon hit-testing uses `renderer.point(for: mapPoint)` then `renderer.path.contains(...)` — not map coordinate comparison.
- `MapActionCard` is a floating bubble anchored to the pin's screen coordinate, not a bottom sheet.
- Offline tiles: `LocalTileOverlay` / `OfflineTileManager` — no actual tile files bundled, falls back gracefully to blank tiles.
- Patrol area coordinates are hardcoded in `Resources/PortStewartZones.areaCoordinates` (10 named areas).
- GPS in simulator: 8-second timeout falls back to Port Stewart coords `(-14.7019, 143.7075)`.

## Cloud sync scope

Do not add real Supabase API calls, real S3 uploads, MapKit paid tiers, or any live network-dependent feature. `Services/API/` files are stubs. `SyncEngine.triggerSync()` is a no-op. The "Cloud Sync" view in Hub is a simulation only.

## Tab structure

`MainTabView` has **5 tabs**: Map, Activity (Sightings/Patrols/Tasks segments), Guide (species field guide), Safety (`SafetyCheckInView`), Hub. `HubView` is a tile grid linking to Dashboard, Supplies, Day Sync, Zones, Cloud Sync, Handover, Equipment, Hazards, and Settings.

## Design system

`Views/DesignSystem.swift` — warm Australian bushland palette. Key tokens:
- `Color.dsPrimary` (#2A5C3F), `Color.dsAccent` (#C4692A), `Color.dsBackground` (#F7F3EC)
- `DSFont.*`: largeTitle / title / headline / subhead / body / callout / footnote / caption / badge / mono
- `DSSpace.*`: xs / sm / md / lg / xl / xxxl
- `DSRadius.*`: xs / sm / md / lg
- `.dsCard()` / `.dsElevatedCard()` view modifiers

## Species model

`InvasiveSpecies` enum (in `Models/Enums/`) replaces `LantanaVariant`. Cases: lantana, rubberVine, pricklyAcacia, sicklepod, giantRatsTailGrass, pondApple, unknown. `InvasiveSpecies.from(legacyVariant:)` maps old Lantana variant strings → `.lantana`. CoreData still stores species as String via `variant` attribute — no schema migration needed.

## demov3 features (branch: demov3)

12 features added on top of `demov2`. All are fully offline; no new cloud dependencies.

| Feature | Key files |
|---|---|
| **Safety Check-In** | `SafetyCheckInView.swift`, `SafetyCheckInViewModel.swift` — countdown ring, UNNotification, "I'm Safe" reset |
| **Hazard Logger** | `HazardLogView.swift`, `LogHazardView.swift`, `HazardViewModel.swift` — GPS hazard records |
| **Voice Notes** | `VoiceNoteRecorder.swift` (component) — AVAudioRecorder/AVAudioPlayer, 3 states: idle/recording/recorded; saved to `SightingLog.voiceNotePath` |
| **Photo Size Estimation** | `SizeEstimationOverlay.swift` — draggable rect, reference object picker, area estimate in m²; saves to `SightingLog.infestationAreaEstimate` |
| **Phenology Alerts** | `PhenologyAlerts.swift` (`PhenologyAlertStore`) — real Cape York phenology for all 6 species; banner in `LogSightingView` |
| **Herbicide Checker** | `HerbicideCheckerView.swift`, `HerbicideDatabase.swift` — product/species/method compatibility |
| **Treatment Effectiveness** | `TreatmentFollowUpView.swift`, `TreatmentEffectivenessViewModel.swift` — `RegrowthLevel` enum (none/light/moderate/heavy), timeline |
| **Per-Area Checklists** | `AreaChecklistView.swift`, `PatrolViewModel+Checklist.swift`, `AreaChecklists.swift` |
| **Pesticide Stock Alerts** | `PesticideAlertBanner.swift` (component) — surfaces on `DashboardView` when any stock is critical |
| **Equipment Log** | `EquipmentListView.swift`, `AddEquipmentView.swift`, `AddMaintenanceRecordView.swift`, `EquipmentViewModel.swift` |
| **Ranger Status Broadcast** | `RangerStatusView.swift`, `RangerStatusViewModel.swift`, `RangerStatus.swift` — status over mesh |
| **Night Mode** | `AppThemeViewModel.swift` (`AppTheme` enum), `RedLightOverlay.swift` (`RedLightModifier`) — colour-multiply overlay, no view changes needed |

### App-level wiring (demov3)

`ewbappApp.swift` holds two additional `@StateObject`s injected as `.environmentObject()`:
- `AppThemeViewModel` — provides `.preferredColorScheme` and drives `RedLightModifier`
- `SafetyCheckInViewModel` — shared instance for the Safety tab

## Demo features (branch: demonewui)

These are demo/showcase views not wired to real V3 services:

- **`Demo/DemoMeshSyncView.swift`** — animated Bluetooth mesh sync with peer discovery. After completion, shows a "Zone Conflicts" link to `ConflictResolverView`.
- **`Demo/DemoLiveSyncView.swift`** — fake V3 cloud sync dashboard. Shows Supabase DB + Storage (primary) and S3 (cold backup replica). Live CoreData counts per table, Starlink-style jittery MB/s upload speed (2–14 MB/s), DB snapshot export simulation. Accessible from Hub → Cloud Sync.
- **`Views/Hub/ConflictResolverView.swift`** — demo mesh sync conflict resolver. Shows 3 fake zone boundary conflicts with Keep Mine / Keep Theirs / Merge actions. Accessible from Day Sync after sync completes.
- **`Views/Hub/ShiftHandoverView.swift`** — end-of-shift summary card. Reads live CoreData: today's sightings, untreated count, species breakdown, patrol duration/checklist %, pesticide usage, open/overdue tasks, sync status. ShareLink exports a formatted text summary. Accessible from Hub → Handover.
- **`Views/Map/BloomCalendarView.swift`** — seasonal bloom risk calendar for all 6 invasive species. Shows per-month risk level (HIGH/MODERATE/Low) based on hardcoded Cape York phenology data. Accessible via "Bloom" capsule button in map top bar.
- **`Views/Hub/ConflictResolverView.swift`** — see above.

## Patrol checklist stamina metric

`PatrolChecklistItem` (in `Models/Domain/`) now has `timeEstimateMins: Int` (default 10). `PortStewartZones.defaultChecklist` includes realistic estimates per task. `PatrolViewModel` exposes `plannedMinutes` and `elapsedMinutes`. `ActivePatrolView` shows a two-tone time-budget bar (green = completed item time, amber = remaining) with a "Running long" warning at 85% of planned time. `ChecklistItemRow` shows a time badge on incomplete items.

## Lantana biocontrol prompt

`LogSightingView` shows `BiocontrolPromptCard` (amber-tinted card) when `selectedSpecies == .lantana`. Three-button segmented row: Observed / Not Seen / Unsure. If "Observed", shows ⚠️ warning about delaying foliar spray. `LogSightingViewModel.BiocontrolObservation` enum appends biocontrol data to notes on save.

## Before/After photo comparison

`TreatmentEntryView` has an "After Photos" section that appends fake filenames. When saved, prepends `"📷 After: N photo(s). "` to outcomeNotes. `SightingDetailView` detects this prefix and shows a `BeforeAfterCard` below the `TreatmentRow` — species icon (before) vs green checkmark (after) in a two-column comparison card.

## Git commits

Do not add a `Co-Authored-By` trailer to any commit message.
