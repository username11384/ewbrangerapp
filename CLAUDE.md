# Lama Lama Rangers — Claude Code Guide

## What this project is
iOS app for Yintjingga Aboriginal Corporation (YAC). Lama Lama Rangers use it to track Lantana camara infestations around Port Stewart, Cape York, QLD. Fully offline-capable. This is a **proof of concept** — it doesn't need to fully work, just demonstrate the architecture.

## Project setup
- **Bundle ID:** `com.immanuel.ewbapp`
- **Xcode project:** `/Users/immanuellam/Documents/ewbapp/ewbapp/ewbapp.xcodeproj`
- **Source root:** `/Users/immanuellam/Documents/ewbapp/ewbapp/ewbapp/`
- **iOS target:** 26.2 (Xcode set this automatically)
- **Git remote:** `https://github.com/username11384/ewbrangerapp.git`
- **Build command:** `xcodebuild -scheme ewbapp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build`

## Key Xcode project settings
- `PBXFileSystemSynchronizedRootGroup` — **never edit `.pbxproj` manually**. All files on disk are auto-included.
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` — every file that uses `@Published` / `ObservableObject` / Combine must have `import Combine` explicitly.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — project-wide MainActor default.

## Architecture
MVVM + Repository pattern. CoreData for persistence. No Supabase (cloud sync fully stubbed).

```
Views (SwiftUI)
  ViewModels (@MainActor ObservableObject)
    Repositories (CoreData CRUD)
      PersistenceController (NSPersistentContainer)
        mainContext  — UI reads
        backgroundContext — all writes
```

## CoreData
- Model file: `CoreData/LamaLamaRangers.xcdatamodeld`
- **No Xcode codegen** — all `NSManagedObject` subclasses are hand-written in `CoreData/ManagedObjects.swift`
- 9 entities: `SightingLog`, `TreatmentRecord`, `PatrolRecord`, `RangerProfile`, `InfestationZone`, `InfestationZoneSnapshot`, `PesticideStock`, `PesticideUsageRecord`, `SyncQueue`
- `viewContext.automaticallyMergesChangesFromParent = true` — background saves propagate to main context automatically, but allow ~150ms before calling `load()` after a background save

## Auth
- PIN-based, fully offline. Single shared PIN hash stored in Keychain.
- First login with any PIN sets it for all rangers.
- Default demo PIN: `1234`
- Demo rangers seeded on first launch: Alice Johnson (Senior Ranger), Bob Smith (Ranger), Carol White (Ranger)
- `AuthManager` is `@MainActor` — call `setPIN` on main queue

## No paid APIs
Supabase is stubbed. `SyncEngine.triggerSync()` is a no-op. Do not add real API calls.

## Map
- `MapView` is `UIViewRepresentable` wrapping `MKMapView`
- Offline tiles: `LocalTileOverlay` / `OfflineTileManager` — no actual tile files bundled, falls back gracefully
- Default centre: Port Stewart (-14.7, 143.7), 50km radius
- Patrol areas have hardcoded coordinates in `PortStewartZones.areaCoordinates`
- Zone overlays: `ZonePolygonOverlay` (MKPolygon subclass) when snapshot exists, `ZoneCircleOverlay` (MKCircle subclass) as fallback from sighting centroid
- Draw mode: tap vertices on map → save as `InfestationZoneSnapshot`
- Floating action card (`MapActionCard`) appears near tapped pin/overlay — not a bottom sheet

## GPS in simulator
8-second timeout fallback to Port Stewart coords (`-14.7019, 143.7075`) so the app doesn't hang waiting for GPS.

## Sync (PoC)
- Cloud sync: fully stubbed, no-op
- Mesh sync: `MeshSyncEngine` uses `MultipeerConnectivity` for Bluetooth peer-to-peer. Service type: `"yac-lantana"`. Metadata only (no photos).

## What's deferred to V2
- Polygon drawing UI was implemented as PoC (tap vertices on map)
- Timeline scrubber view exists but not wired into MapContainerView
- Multiple photos per sighting (model supports 3, UI shows 1)
- Patrol calendar grid view
- WiFi-only photo upload
- Real Supabase cloud sync
