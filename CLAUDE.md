# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

iOS app for Yintjingga Aboriginal Corporation (YAC). Lama Lama Rangers track Lantana camara infestations around Port Stewart, Cape York, QLD. This is **V2** — a fully functional offline app with local-only persistence, Bluetooth mesh sync (MultipeerConnectivity), and no cloud backend. V3 (Supabase cloud sync, real API calls, paid services) has no planned timeline.

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

## V3 scope (not in this codebase)

Do not add: Supabase cloud sync, real API calls, MapKit paid tiers, push notifications, or any network-dependent feature. All `Services/API/` files are stubs and must remain so until V3 is scoped. V3 has no planned timeline.

## Tab structure

`MainTabView` has 5 tabs: Map, Sightings, Patrol, Tasks, More. `MoreView` (in `MainTabView.swift`) is the navigation hub for Guide, Protocol, Zones, Dashboard, Supplies, End of Day Sync, Settings.
