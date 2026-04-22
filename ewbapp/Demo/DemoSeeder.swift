import Foundation
import CoreData
import UIKit

/// Seeds rich fake data for the demo branch. Idempotent — guarded by a UserDefaults flag.
struct DemoSeeder {

    static func seed(in persistence: PersistenceController) {
        guard !UserDefaults.standard.bool(forKey: "demoDataSeeded_v3") else { return }

        let variantPhotos = seedPhotos()
        let ctx = persistence.backgroundContext
        var seedCompleted = false
        ctx.performAndWait {
            let rangers = (try? ctx.fetchAll(RangerProfile.self)) ?? []
            guard rangers.count >= 3 else { return }

            let alice = rangers.first { $0.displayName == "Alice Johnson" } ?? rangers[0]
            let bob   = rangers.first { $0.displayName == "Bob Smith"    } ?? rangers[1]
            let carol = rangers.first { $0.displayName == "Carol White"  } ?? rangers[2]

            // --------------------------------------------------------
            // ZONES
            // --------------------------------------------------------
            let zoneSpecs: [(name: String, status: String, variant: String, lat: Double, lon: Double)] = [
                ("North Creek Gully",    "active",         "lantana",          -14.685, 143.712),
                ("Boundary Road East",   "underTreatment", "rubberVine",       -14.718, 143.698),
                ("Homestead Track",      "cleared",        "pricklyAcacia",    -14.703, 143.722),
                ("Rocky Point Scrub",    "active",         "giantRatsTailGrass", -14.695, 143.683),
                ("Mangrove Flat",        "underTreatment", "pondApple",        -14.725, 143.715),
                ("Station Dam",          "cleared",        "sicklepod",        -14.710, 143.730),
            ]

            var zones: [InfestationZone] = []
            for spec in zoneSpecs {
                let zone = InfestationZone(context: ctx)
                zone.id = UUID()
                zone.createdAt = ago(days: 180)
                zone.updatedAt = ago(days: 7)
                zone.name = spec.name
                zone.status = spec.status
                zone.dominantVariant = spec.variant
                zone.syncStatus = SyncStatus.synced.rawValue

                // Diamond polygon around centroid (~300 m radius)
                let d = 0.003
                let snap = InfestationZoneSnapshot(context: ctx)
                snap.id = UUID()
                snap.snapshotDate  = ago(days: 30)
                snap.createdByRangerID = alice.id
                snap.area          = 90_000  // ~9 ha
                snap.polygonCoordinates = [
                    [spec.lat + d, spec.lon],
                    [spec.lat,     spec.lon + d],
                    [spec.lat - d, spec.lon],
                    [spec.lat,     spec.lon - d],
                ] as NSArray
                snap.parentZone = zone
                zones.append(zone)
            }

            // --------------------------------------------------------
            // SIGHTINGS  (28 entries spread over 6 months)
            // All offsets satisfy |latOff|+|lonOff| <= 0.002 so every pin
            // sits clearly inside its zone's diamond polygon (radius d=0.003).
            // --------------------------------------------------------
            typealias SD = (ranger: RangerProfile, variant: String, size: String,
                            lat: Double, lon: Double, daysAgo: Int, zoneIdx: Int?)
            let sightingSpecs: [SD] = [
                // Zone 0 — North Creek Gully   (lantana)
                (alice, "lantana",           "large",  -14.685,  143.712,  168, 0),
                (carol, "lantana",           "large",  -14.684,  143.713,  134, 0),
                (bob,   "lantana",           "large",  -14.686,  143.713,   99, 0),
                (alice, "lantana",           "small",  -14.684,  143.711,   64, 0),
                (alice, "lantana",           "medium", -14.686,  143.711,   22, 0),
                (alice, "lantana",           "medium", -14.685,  143.7135,   2, 0),
                // Zone 1 — Boundary Road East  (rubberVine)
                (bob,   "rubberVine",        "medium", -14.718,  143.698,  162, 1),
                (alice, "rubberVine",        "large",  -14.717,  143.699,  127, 1),
                (carol, "rubberVine",        "medium", -14.719,  143.699,   92, 1),
                (carol, "rubberVine",        "large",  -14.717,  143.697,   50, 1),
                (carol, "rubberVine",        "medium", -14.719,  143.697,   14, 1),
                // Zone 2 — Homestead Track     (pricklyAcacia)
                (carol, "pricklyAcacia",     "small",  -14.703,  143.722,  155, 2),
                (alice, "pricklyAcacia",     "medium", -14.702,  143.7225, 106, 2),
                (bob,   "pricklyAcacia",     "medium", -14.704,  143.7225,  57, 2),
                (bob,   "pricklyAcacia",     "small",  -14.703,  143.721,   18, 2),
                // Zone 3 — Rocky Point Scrub   (giantRatsTailGrass)
                (alice, "giantRatsTailGrass","medium", -14.695,  143.683,  148, 3),
                (bob,   "giantRatsTailGrass","medium", -14.694,  143.684,  120, 3),
                (bob,   "giantRatsTailGrass","medium", -14.696,  143.6825,  78, 3),
                (alice, "giantRatsTailGrass","medium", -14.6945, 143.682,   43, 3),
                (alice, "giantRatsTailGrass","large",  -14.6955, 143.684,   10, 3),
                // Zone 4 — Mangrove Flat       (pondApple)
                (bob,   "pondApple",         "small",  -14.725,  143.715,  141, 4),
                (alice, "pondApple",         "small",  -14.724,  143.7155,  85, 4),
                (bob,   "pondApple",         "small",  -14.726,  143.7145,  36, 4),
                (bob,   "pondApple",         "medium", -14.7245, 143.714,    7, 4),
                // Zone 5 — Station Dam         (sicklepod)
                (carol, "sicklepod",         "small",  -14.710,  143.730,  113, 5),
                (carol, "sicklepod",         "large",  -14.709,  143.731,   71, 5),
                (carol, "sicklepod",         "large",  -14.711,  143.729,   29, 5),
                (carol, "sicklepod",         "small",  -14.709,  143.729,    4, 5),
            ]

            var sightings: [SightingLog] = []
            for spec in sightingSpecs {
                let s = SightingLog(context: ctx)
                s.id = UUID()
                let date = ago(days: spec.daysAgo)
                s.createdAt = date
                s.updatedAt = date
                s.latitude  = spec.lat
                s.longitude = spec.lon
                s.horizontalAccuracy = 8.0
                s.variant = spec.variant
                s.infestationSize = spec.size
                s.ranger = spec.ranger
                s.deviceID = "demo-device"
                s.syncStatus = SyncStatus.synced.rawValue
                s.photoFilenames = variantPhotos[spec.variant] as NSArray?
                if let idx = spec.zoneIdx { s.infestationZone = zones[idx] }
                sightings.append(s)
            }

            // --------------------------------------------------------
            // TREATMENT RECORDS  (first 18 sightings)
            // --------------------------------------------------------
            let methods  = ["cutStump", "splatGun", "foliarSpray", "basalBark", "mechanical", "stemInjection"]
            let products = ["Garlon 600", "Access", "Glyphosate 360", "Tordon 75-D", "Starane Advanced"]
            let outcomes = [
                "Cut stumps painted immediately, good coverage achieved.",
                "Foliar spray applied across canopy. Regrowth expected in 60 days.",
                "Basal bark treatment on all stems >5 cm diameter.",
                "Splat gun applied to accessible stems, 95% coverage.",
                "Full canopy foliar treatment. Follow-up scheduled at 60 days.",
            ]

            var treatments: [TreatmentRecord] = []
            for (i, sighting) in sightings.prefix(18).enumerated() {
                let t = TreatmentRecord(context: ctx)
                t.id = UUID()
                let date = (sighting.createdAt ?? Date()).addingTimeInterval(7_200)
                t.treatmentDate = date
                t.createdAt = date
                t.updatedAt = date
                t.method = methods[i % methods.count]
                t.herbicideProduct = products[i % products.count]
                t.outcomeNotes = outcomes[i % outcomes.count]
                t.syncStatus = SyncStatus.synced.rawValue
                t.ranger = sighting.ranger
                t.sighting = sighting
                if i % 4 == 0 { t.followUpDate = date.addingTimeInterval(60 * 86_400) }
                treatments.append(t)
            }

            // --------------------------------------------------------
            // PATROL RECORDS  (10 patrols across the past 3 weeks)
            // --------------------------------------------------------
            typealias PD = (ranger: RangerProfile, area: String, daysAgo: Int)
            let patrolSpecs: [PD] = [
                (alice, "North Beach Dunes",        3),
                (bob,   "Creek Line East",          3),
                (carol, "Central Clearing",         4),
                (alice, "Headland Track",           7),
                (bob,   "Mangrove Edge",            7),
                (carol, "North Beach Dunes",       10),
                (alice, "River Mouth Flats",       14),
                (bob,   "Airstrip Corridor",       14),
                (carol, "Camping Ground Perimeter",17),
                (alice, "Southern Scrub Belt",     21),
            ]

            for spec in patrolSpecs {
                let p = PatrolRecord(context: ctx)
                p.id = UUID()
                let start = ago(days: spec.daysAgo)
                p.patrolDate  = start
                p.startTime   = start
                p.endTime     = start.addingTimeInterval(10_800)   // 3 h patrol
                p.areaName    = spec.area
                p.createdAt   = start
                p.updatedAt   = start
                p.syncStatus  = SyncStatus.synced.rawValue
                p.ranger      = spec.ranger
                p.notes       = "Patrol complete. All invasive plants logged and GPS-tagged."

                let checklist: [PatrolChecklistItem] = [
                    .init(label: "GPS unit charged",       isComplete: true, completedAt: start),
                    .init(label: "Herbicide mix prepared", isComplete: true, completedAt: start.addingTimeInterval(600)),
                    .init(label: "Safety gear donned",     isComplete: true, completedAt: start.addingTimeInterval(900)),
                    .init(label: "Area perimeter walked",  isComplete: true, completedAt: start.addingTimeInterval(3_600)),
                    .init(label: "All sightings logged",   isComplete: true, completedAt: start.addingTimeInterval(9_000)),
                ]
                p.checklistItems = (try? JSONEncoder().encode(checklist)).map { $0 as NSData }
            }

            // --------------------------------------------------------
            // PESTICIDE STOCK + USAGE
            // --------------------------------------------------------
            typealias StockSpec = (name: String, unit: String, qty: Double, threshold: Double)
            let stockSpecs: [StockSpec] = [
                ("Garlon 600",     "litres",  8.5, 2.0),
                ("Access",         "litres",  4.2, 1.0),
                ("Glyphosate 360", "litres", 12.0, 3.0),
            ]
            var stocks: [PesticideStock] = []
            for spec in stockSpecs {
                let stock = PesticideStock(context: ctx)
                stock.id = UUID()
                stock.createdAt = ago(days: 180)
                stock.updatedAt = ago(days: 2)
                stock.productName     = spec.name
                stock.unit            = spec.unit
                stock.currentQuantity = spec.qty
                stock.minThreshold    = spec.threshold
                stock.syncStatus      = SyncStatus.synced.rawValue
                stocks.append(stock)
            }

            typealias UR = (stockIdx: Int, qty: Double, daysAgo: Int, ranger: RangerProfile)
            let usageSpecs: [UR] = [
                (0, 0.5,  3, alice), (0, 0.8,  7, bob),   (0, 0.3, 14, carol),
                (0, 1.2, 21, alice), (1, 0.4,  4, bob),   (1, 0.6, 10, carol),
                (1, 0.3, 18, alice), (2, 1.5,  5, bob),   (2, 0.9, 12, carol),
                (2, 2.0, 25, alice), (2, 0.7, 35, bob),
            ]
            for spec in usageSpecs {
                let u = PesticideUsageRecord(context: ctx)
                u.id = UUID()
                let date = ago(days: spec.daysAgo)
                u.createdAt     = date
                u.updatedAt     = date
                u.usedAt        = date
                u.usedQuantity  = spec.qty
                u.syncStatus    = SyncStatus.synced.rawValue
                u.ranger        = spec.ranger
                u.stock         = stocks[spec.stockIdx]
            }

            // --------------------------------------------------------
            // RANGER TASKS
            // --------------------------------------------------------
            typealias TD = (title: String, ranger: RangerProfile, priority: String, complete: Bool, daysAgo: Int)
            let taskSpecs: [TD] = [
                ("Lantana regrowth check — North Creek Gully",    alice, "high",   false, 14),
                ("Rubber vine follow-up spray — Boundary Road",   bob,   "high",   false,  7),
                ("Photo documentation — Station Dam sicklepod",   carol, "medium", true,  21),
                ("Restock Garlon 600 and Tordon 75-D",            alice, "medium", false,  3),
                ("Check lantana biocontrol release site",         bob,   "low",    false, 10),
                ("Update zone polygons after wet season rain",    carol, "medium", true,  18),
                ("Pond apple mechanical removal — Mangrove Flat", alice, "high",   false,  2),
            ]
            for spec in taskSpecs {
                let task = RangerTask(context: ctx)
                task.id = UUID()
                let date = ago(days: spec.daysAgo)
                task.createdAt  = date
                task.updatedAt  = date
                task.title      = spec.title
                task.priority   = spec.priority
                task.isComplete = spec.complete
                task.syncStatus     = SyncStatus.synced.rawValue
                task.assignedRanger = spec.ranger
            }

            try? ctx.save()
            seedCompleted = true
        }

        guard seedCompleted else { return }

        // Force main context to pick up background changes immediately
        DispatchQueue.main.async {
            persistence.mainContext.refreshAllObjects()
        }

        // Fake a recent cloud sync so the dashboard & settings show "synced"
        UserDefaults.standard.set(Date().addingTimeInterval(-3_600), forKey: "lastSyncTimestamp")
        UserDefaults.standard.set(true, forKey: "demoDataSeeded_v3")
    }

    // MARK: - Photo helpers

    /// Copies each bundled demo_lantana_N asset to Documents/Photos/ once.
    /// Returns a dict mapping variant string → [filename] to attach to sightings.
    @discardableResult
    static func seedPhotos() -> [String: [String]] {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Photos")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // asset name → variant keys that should use it
        let assetMap: [(asset: String, variants: [String])] = [
            ("demo_lantana_1", ["lantana"]),
            ("demo_lantana_2", ["rubberVine"]),
            ("demo_lantana_3", ["pricklyAcacia"]),
            ("demo_lantana_4", ["giantRatsTailGrass"]),
            ("demo_lantana_5", ["pondApple"]),
            ("demo_lantana_6", ["sicklepod", "unknown"]),
        ]

        var variantPhotos: [String: [String]] = [:]
        for entry in assetMap {
            guard let image = UIImage(named: entry.asset),
                  let data  = image.jpegData(compressionQuality: 0.85) else { continue }
            let filename = "\(entry.asset).jpg"
            let url = dir.appendingPathComponent(filename)
            if !FileManager.default.fileExists(atPath: url.path) {
                try? data.write(to: url)
            }
            for variant in entry.variants {
                variantPhotos[variant] = [filename]
            }
        }
        return variantPhotos
    }

    // MARK: - Helper
    private static func ago(days n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
    }
}
