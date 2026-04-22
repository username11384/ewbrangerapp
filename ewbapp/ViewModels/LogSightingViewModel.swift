import Combine
import CoreData
import Foundation
import CoreLocation
import UIKit

@MainActor
final class LogSightingViewModel: ObservableObject {
    @Published var capturedLocation: CLLocation?
    @Published var accuracyLevel: LocationManager.AccuracyLevel = .unknown
    @Published var selectedSpecies: InvasiveSpecies?
    @Published var selectedSize: InfestationSize = .small
    @Published var notes: String = ""
    @Published var photoFilenames: [String] = []
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var didSave = false
    @Published var biocontrolObservation: BiocontrolObservation = .notChecked
    /// Area estimate produced by SizeEstimationOverlay (Feature 11), e.g. "~4.2 m²"
    @Published var infestationAreaEstimate: String? = nil
    /// File path to a recorded voice note (set by VoiceNoteRecorder before save)
    @Published var voiceNotePath: String? = nil

    enum BiocontrolObservation: String, CaseIterable {
        case notChecked, observed, notObserved, unsure

        var displayName: String {
            switch self {
            case .notChecked:  return "Not checked"
            case .observed:    return "Observed"
            case .notObserved: return "Not seen"
            case .unsure:      return "Unsure"
            }
        }
    }

    var canSave: Bool {
        capturedLocation != nil && selectedSpecies != nil
    }

    var controlRecommendation: String? {
        guard let species = selectedSpecies else { return nil }
        let methods = species.controlMethods.map { $0.displayName }.joined(separator: " or ")
        return "Recommended: \(methods)"
    }

    private let locationManager: LocationManager
    private let sightingRepository: SightingRepository
    private let rangerID: UUID

    init(locationManager: LocationManager, persistence: PersistenceController, rangerID: UUID) {
        self.locationManager = locationManager
        self.sightingRepository = SightingRepository(persistence: persistence)
        self.rangerID = rangerID
        Task { await captureLocation() }
    }

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

    func capturePhoto() async {
        let filename = "sighting_\(UUID().uuidString).heif"
        photoFilenames.append(filename)
    }

    func save() async {
        guard canSave, let location = capturedLocation, let species = selectedSpecies else { return }
        isSaving = true
        saveError = nil
        do {
            var finalNotes = notes
            if species == .lantana && biocontrolObservation != .notChecked {
                let bioNote = "[Lantana bug: \(biocontrolObservation.displayName)]"
                finalNotes = finalNotes.isEmpty ? bioNote : finalNotes + " " + bioNote
                if biocontrolObservation == .observed {
                    finalNotes += " ⚠️ Biocontrol present - consider delaying herbicide"
                }
            }
            // Append area estimate to notes if provided
            if let area = infestationAreaEstimate {
                let areaNote = "[Estimated area: \(area)]"
                finalNotes = finalNotes.isEmpty ? areaNote : finalNotes + " " + areaNote
            }
            let sighting = try await sightingRepository.createSighting(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                horizontalAccuracy: location.horizontalAccuracy,
                species: species,
                infestationSize: selectedSize,
                notes: finalNotes.isEmpty ? nil : finalNotes,
                photoFilenames: photoFilenames,
                rangerID: rangerID
            )
            // Persist area estimate and voice note path on the CoreData entity
            if infestationAreaEstimate != nil || voiceNotePath != nil,
               let ctx = sighting.managedObjectContext {
                ctx.performAndWait {
                    if let area = infestationAreaEstimate {
                        sighting.infestationAreaEstimate = area
                    }
                    if let path = voiceNotePath {
                        sighting.voiceNotePath = path
                    }
                    try? ctx.save()
                }
            }
            _ = sighting
            didSave = true
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }
}
