import Combine
import CoreData
import CoreLocation
import Foundation

@MainActor
final class HazardViewModel: ObservableObject {
    @Published var hazards: [HazardLog] = []
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var didSave = false

    // Form state for LogHazardView
    @Published var selectedType: HazardType = .other
    @Published var selectedSeverity: HazardSeverity = .low
    @Published var title: String = ""
    @Published var notes: String = ""
    @Published var capturedLocation: CLLocation?
    @Published var accuracyLevel: LocationManager.AccuracyLevel = .unknown
    @Published var photoPath: String?

    enum HazardType: String, CaseIterable {
        case fire             = "Fire"
        case flood            = "Flood"
        case injuredAnimal    = "Injured Animal"
        case unsafeTrack      = "Unsafe Track"
        case infraDamage      = "Infrastructure Damage"
        case other            = "Other"

        var iconName: String {
            switch self {
            case .fire:          return "flame.fill"
            case .flood:         return "drop.fill"
            case .injuredAnimal: return "pawprint.fill"
            case .unsafeTrack:   return "exclamationmark.triangle.fill"
            case .infraDamage:   return "wrench.and.screwdriver.fill"
            case .other:         return "questionmark.circle.fill"
            }
        }
    }

    enum HazardSeverity: String, CaseIterable {
        case low    = "Low"
        case medium = "Medium"
        case high   = "High"

        var color: String {
            switch self {
            case .low:    return "dsStatusCleared"
            case .medium: return "dsStatusTreat"
            case .high:   return "dsStatusActive"
            }
        }
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && capturedLocation != nil
    }

    private let persistence: PersistenceController
    private let locationManager: LocationManager

    init(persistence: PersistenceController, locationManager: LocationManager) {
        self.persistence = persistence
        self.locationManager = locationManager
        Task { await captureLocation() }
    }

    // MARK: - Location

    func captureLocation() async {
        let location = await locationManager.captureLocation()
        capturedLocation = location
        accuracyLevel = locationManager.accuracyLevel
    }

    func recaptureLocation() {
        capturedLocation = nil
        accuracyLevel = .unknown
        Task { await captureLocation() }
    }

    // MARK: - Fetch

    func load() {
        let request = HazardLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HazardLog.timestamp, ascending: false)]
        hazards = (try? persistence.mainContext.fetch(request)) ?? []
    }

    // MARK: - Save

    func logHazard() async {
        guard canSave, let location = capturedLocation else { return }
        isSaving = true
        saveError = nil
        let context = persistence.backgroundContext
        await context.perform {
            let log = HazardLog(context: context)
            log.id = UUID()
            log.timestamp = Date()
            log.title = self.title.trimmingCharacters(in: .whitespaces)
            log.hazardType = self.selectedType.rawValue
            log.severity = self.selectedSeverity.rawValue
            log.notes = self.notes.isEmpty ? nil : self.notes
            log.latitude = location.coordinate.latitude
            log.longitude = location.coordinate.longitude
            log.photoPath = self.photoPath
            log.syncedToCloud = false
            try? context.save()
        }
        load()
        didSave = true
        isSaving = false
    }

    // MARK: - Delete

    func delete(_ hazard: HazardLog) {
        persistence.mainContext.delete(hazard)
        persistence.save(context: persistence.mainContext)
        load()
    }
}
