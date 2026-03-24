
    # Lama Lama Rangers — Project Handoff

    ## What this project is
    A native iOS app (Swift + SwiftUI, iOS 16+, Bundle ID: `org.yac.llamarangers`) for Yintjingga Aboriginal Corporation (YAC). Lama Lama Rangers use it to log and manage Lantana camara (invasive weed) infestations in Port
    Stewart, Cape York, Queensland — a remote area with **no reliable internet**.

    ## Xcode project location
    /Users/immanuellam/Documents/ewbapp/ewbapp/
    ├── ewbapp/           ← all Swift source files live here
    └── ewbapp.xcodeproj/

    ## Implementation status
    The technical plan has been approved and implementation is **in progress**. Three parallel agents were launched to create:

    1. **Foundation agent** — Enums, DTOs, Domain models, CoreData schema, PersistenceController, AppEnvironment, Config files, Resources
    2. **Services agent** — Auth (AuthManager, KeychainService), Location (LocationManager), API (SupabaseClient, SightingAPIService, PatrolAPIService, RangerAPIService, ZoneAPIService, PesticideAPIService), Sync
    (SyncEngine, MeshSyncEngine, ConflictResolver, SyncQueueManager, PhotoUploadManager), Map (LocalTileOverlay, OfflineTileManager)
    3. **Repositories + ViewModels agent** — All repository protocols + implementations, all ViewModels

    **Not yet created (next session must complete):**
    - All Views (see full list below)
    - The main app entry point update (`LamaLamaRangersApp.swift` — replace the template)
    - Unit tests and UI tests
    - Add all new files to `ewbapp.xcodeproj/project.pbxproj` (Xcode project file)

    ## Architecture
    **MVVM + Repository pattern**
    - Views (SwiftUI) → ViewModels (`@MainActor`, `ObservableObject`) → Repositories (protocol-injected) → CoreData (two contexts: `mainContext` for UI, `backgroundContext` for sync writes)
    - `AppEnvironment` struct injected via `.environment()`
    - Two sync tiers: Bluetooth mesh (MultipeerConnectivity, end-of-day, PoC) + Supabase REST cloud sync

    ## Full folder structure expected
    ewbapp/
    ├── LamaLamaRangersApp.swift              ← needs updating from template
    ├── AppEnvironment.swift                  ✓
    ├── CoreData/
    │   ├── LamaLamaRangers.xcdatamodeld     ✓ (XML model)
    │   ├── PersistenceController.swift       ✓
    │   └── CoreDataHelpers.swift             ✓
    ├── Models/
    │   ├── Enums/  (LantanaVariant, InfestationSize, TreatmentMethod, SyncStatus, RangerRole) ✓
    │   ├── DTOs/   (SightingLogDTO, TreatmentRecordDTO, PatrolRecordDTO, RangerProfileDTO, ZoneSnapshotDTO) ✓
    │   └── Domain/ (PatrolChecklistItem, SeasonalAlert) ✓
    ├── Repositories/
    │   ├── Protocols/ (SightingRepositoryProtocol, PatrolRepositoryProtocol, RangerRepositoryProtocol, ZoneRepositoryProtocol) ✓
    │   ├── SightingRepository.swift          ✓
    │   ├── TreatmentRepository.swift         ✓
    │   ├── PatrolRepository.swift            ✓
    │   ├── RangerRepository.swift            ✓
    │   └── ZoneRepository.swift              ✓
    ├── Services/
    │   ├── Sync/ (SyncEngine, SyncQueueManager, ConflictResolver, PhotoUploadManager, MeshSyncEngine) ✓
    │   ├── API/ (SupabaseClient, SightingAPIService, PatrolAPIService, RangerAPIService, ZoneAPIService, PesticideAPIService) ✓
    │   ├── Location/ (LocationManager) ✓
    │   ├── Auth/ (AuthManager, KeychainService) ✓
    │   └── Map/ (LocalTileOverlay, OfflineTileManager) ✓
    ├── ViewModels/
    │   ├── LoginViewModel.swift              ✓
    │   ├── LogSightingViewModel.swift        ✓
    │   ├── SightingListViewModel.swift       ✓
    │   ├── SightingDetailViewModel.swift     ✓
    │   ├── MapViewModel.swift                ✓
    │   ├── PatrolViewModel.swift             ✓
    │   ├── DashboardViewModel.swift          ✓
    │   ├── PesticideViewModel.swift          ✓
    │   ├── MeshSyncViewModel.swift           ✓
    │   └── SettingsViewModel.swift           ✓
    ├── Views/                                ← NOT YET CREATED
    │   ├── App/ (ContentView.swift, MainTabView.swift)
    │   ├── Login/ (LoginView.swift, PINEntryView.swift)
    │   ├── Map/ (MapView.swift, MapContainerView.swift, TimelineScrubberView.swift, LayerToggleView.swift, SightingPinAnnotation.swift, ZonePolygonOverlay.swift)
    │   ├── Sighting/ (LogSightingView.swift, VariantPickerView.swift, SizePickerView.swift, GPSCaptureView.swift, PhotoCaptureView.swift, ControlRecommendationView.swift, SightingListView.swift, SightingDetailView.swift)
    │   ├── Patrol/ (PatrolView.swift, PatrolListView.swift, ActivePatrolView.swift, PatrolDetailView.swift)
    │   ├── Guide/ (VariantGuideView.swift, VariantDetailView.swift)
    │   ├── Protocol/ (ControlProtocolView.swift)
    │   ├── Dashboard/ (DashboardView.swift)
    │   ├── Pesticide/ (PesticideListView.swift, PesticideDetailView.swift, LogUsageView.swift)
    │   ├── MeshSync/ (MeshSyncView.swift)
    │   ├── Settings/ (SettingsView.swift)
    │   └── Components/ (SyncStatusBadge.swift, VariantColourDot.swift, SeasonalAlertBanner.swift, LargeButton.swift, OfflineIndicatorView.swift)
    ├── Resources/
    │   ├── LantanaVariantContent.swift       ✓
    │   └── PortStewartZones.swift            ✓
    ├── Config/
    │   ├── AppConfig.swift                   ✓
    │   ├── SeasonalAlertConfig.swift         ✓
    │   └── SyncConfig.swift                  ✓
    └── Tests/                                ← NOT YET CREATED
        ├── UnitTests/ (ConflictResolverTests, ControlProtocolLogicTests, SyncQueueManagerTests, SeasonalAlertTests)
        └── UITests/ (LogSightingFlowTests, LoginFlowTests)

    ## Key technical decisions
    - **CoreData over SwiftData** — iOS 16 min target, SwiftData is iOS 17+
    - **Supabase over CloudKit** — Data sovereignty (self-host on AU VPS), custom RLS, no Apple ID requirement
    - **Sync strategy** — Last-Write-Wins (LWW), server authoritative on scalars, photo filenames always union-merged (never lost)
    - **Offline tiles** — MBTiles (SQLite) via `LocalTileOverlay`, delivered as ODR asset or bundled. Port Stewart ±30km radius, zoom 10–18
    - **Mesh sync** — MultipeerConnectivity (`MCNearbyServiceAdvertiser` + `MCNearbyServiceBrowser`), service type `"yac-lantana"`, PoC: metadata only (no photo sync), auto-accept all peers

    ## CoreData entities
    SightingLog, TreatmentRecord, PatrolRecord, RangerProfile, InfestationZone, InfestationZoneSnapshot, PesticideStock, PesticideUsageRecord, SyncQueue

    All entities have: `id` (UUID), `createdAt`, `updatedAt`, `syncStatus` (Int16).

    ## Navigation structure
    TabView with 4 tabs: Map | Sighting List | Patrol | More (Guide, Protocol, Dashboard, Supplies, Settings)

    ## What next session must do
    1. Verify all ✓ files were written correctly (check with `ls` in each directory)
    2. Create all Views (listed above under Views/ — NOT YET CREATED)
    3. Update `LamaLamaRangersApp.swift` to use `AppEnvironment` and show `MainTabView`
    4. Create unit tests and UI tests
    5. Add all Swift files to `ewbapp.xcodeproj/project.pbxproj` (use Xcode or `xcode-build-server` / manually edit pbxproj)
    6. Ensure `SQLite3` is linked in the Xcode project (for `LocalTileOverlay`)
    7. Add `NSLocationWhenInUseUsageDescription` to Info.plist
    8. Add `MultipeerConnectivity` capability and Privacy strings to Info.plist

    ## User preferences
    - iOS 16+ minimum
    - Offline-first is the primary constraint — everything must work in Airplane Mode
    - Field UX: large touch targets (min 44pt), glove-friendly, fast (<60s to log a sighting)
    - No emoji in code or comments
    - Keep solutions simple — do not over-engineer

    ---
