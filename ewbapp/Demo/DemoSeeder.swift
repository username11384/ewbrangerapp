import Foundation
import CoreData
import UIKit

/// Seeds rich fake data for the demo branch. Idempotent — guarded by a UserDefaults flag.
struct DemoSeeder {

    static func seed(in persistence: PersistenceController) {
        guard !UserDefaults.standard.bool(forKey: "demoDataSeeded") else { return }

        let variantPhotos = seedPhotos()
        let ctx = persistence.backgroundContext
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
                ("North Creek Gully",    "active",         "pink",         -14.685, 143.712),
                ("Boundary Road East",   "underTreatment", "red",          -14.718, 143.698),
                ("Homestead Track",      "cleared",        "pinkEdgedRed", -14.703, 143.722),
                ("Rocky Point Scrub",    "active",         "orange",       -14.695, 143.683),
                ("Mangrove Flat",        "underTreatment", "white",        -14.725, 143.715),
                ("Station Dam",          "cleared",        "pink",         -14.710, 143.730),
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
                snap.zone = zone
                zones.append(zone)
            }

            // --------------------------------------------------------
            // SIGHTINGS  (28 entries spread over 6 months)
            // --------------------------------------------------------
            typealias SD = (ranger: RangerProfile, variant: String, size: String,
                            lat: Double, lon: Double, daysAgo: Int, zoneIdx: Int?)
            let sightingSpecs: [SD] = [
                (alice, "pink",         "large",  -14.685, 143.712, 168, 0),
                (bob,   "red",          "medium", -14.718, 143.698, 162, 1),
                (carol, "pinkEdgedRed", "small",  -14.703, 143.722, 155, 2),
                (alice, "pink",         "medium", -14.695, 143.683, 148, 3),
                (bob,   "white",        "small",  -14.725, 143.715, 141, 4),
                (carol, "pink",         "large",  -14.686, 143.714, 134, 0),
                (alice, "red",          "large",  -14.719, 143.700, 127, 1),
                (bob,   "orange",       "medium", -14.696, 143.684, 120, 3),
                (carol, "pink",         "small",  -14.710, 143.730, 113, 5),
                (alice, "pinkEdgedRed", "medium", -14.704, 143.724, 106, 2),
                (bob,   "pink",         "large",  -14.687, 143.711,  99, 0),
                (carol, "red",          "medium", -14.720, 143.697,  92, 1),
                (alice, "white",        "small",  -14.726, 143.716,  85, 4),
                (bob,   "pink",         "medium", -14.697, 143.682,  78, 3),
                (carol, "orange",       "large",  -14.711, 143.731,  71, 5),
                (alice, "pink",         "small",  -14.688, 143.713,  64, 0),
                (bob,   "pinkEdgedRed", "medium", -14.705, 143.723,  57, 2),
                (carol, "red",          "large",  -14.721, 143.699,  50, 1),
                (alice, "pink",         "medium", -14.698, 143.681,  43, 3),
                (bob,   "white",        "small",  -14.727, 143.717,  36, 4),
                (carol, "pink",         "large",  -14.712, 143.729,  29, 5),
                (alice, "orange",       "medium", -14.689, 143.710,  22, 0),
                (bob,   "pink",         "small",  -14.706, 143.725,  18, 2),
                (carol, "red",          "medium", -14.722, 143.696,  14, 1),
                (alice, "pink",         "large",  -14.699, 143.680,  10, 3),
                (bob,   "pinkEdgedRed", "medium", -14.728, 143.718,   7, 4),
                (carol, "pink",         "small",  -14.713, 143.728,   4, 5),
                (alice, "red",          "medium", -14.690, 143.709,   2, 0),
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
            let methods  = ["cutStump", "splatGun", "foliarSpray", "basalBark"]
            let products = ["Garlon 600", "Access", "Glyphosate 360"]
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
                (alice, "North Creek",    3),
                (bob,   "Boundary Road",  3),
                (carol, "Homestead",      4),
                (alice, "Rocky Point",    7),
                (bob,   "Station Dam",    7),
                (carol, "North Creek",   10),
                (alice, "Mangrove Flat", 14),
                (bob,   "South Track",   14),
                (carol, "Eastern Slopes",17),
                (alice, "Homestead",     21),
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
                p.notes       = "Patrol complete. All visible Lantana logged and GPS-tagged."

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
                ("Regrowth check — North Creek Gully",   alice, "high",   false, 14),
                ("Follow-up spray — Boundary Road East", bob,   "high",   false,  7),
                ("Photo documentation — Station Dam",    carol, "medium", true,  21),
                ("Restock Garlon 600",                   alice, "medium", false,  3),
                ("Check biocontrol release site",        bob,   "low",    false, 10),
                ("Update zone polygons after rain",      carol, "medium", true,  18),
                ("Regrowth check — Mangrove Flat",       alice, "high",   false,  2),
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
        }

        // Fake a recent cloud sync so the dashboard & settings show "synced"
        UserDefaults.standard.set(Date().addingTimeInterval(-3_600), forKey: "lastSyncTimestamp")
        UserDefaults.standard.set(true, forKey: "demoDataSeeded")
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
            ("demo_lantana_1", ["pink"]),
            ("demo_lantana_2", ["red"]),
            ("demo_lantana_3", ["pinkEdgedRed"]),
            ("demo_lantana_4", ["orange"]),
            ("demo_lantana_5", ["white"]),
            ("demo_lantana_6", ["unknown"]),
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
