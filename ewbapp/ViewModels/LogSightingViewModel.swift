import Combine
import Foundation
import CoreLocation
import UIKit

@MainActor
final class LogSightingViewModel: ObservableObject {
    @Published var capturedLocation: CLLocation?
    @Published var accuracyLevel: LocationManager.AccuracyLevel = .unknown
    @Published var selectedVariant: LantanaVariant?
    @Published var selectedSize: InfestationSize = .small
    @Published var notes: String = ""
    @Published var photoFilenames: [String] = []
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var didSave = false

    var canSave: Bool {
        capturedLocation != nil && selectedVariant != nil
    }

    var controlRecommendation: String? {
        guard let variant = selectedVariant else { return nil }
        let methods = variant.controlMethods.map { $0.displayName }.joined(separator: " or ")
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
        // In MVP: use UIImagePickerController, save HEIF to Documents/Photos
        // This is called from the view via a coordinator
        let filename = "sighting_\(UUID().uuidString).heif"
        photoFilenames.append(filename)
    }

    func save() async {
        guard canSave, let location = capturedLocation, let variant = selectedVariant else { return }
        isSaving = true
        saveError = nil
        do {
            _ = try await sightingRepository.createSighting(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                horizontalAccuracy: location.horizontalAccuracy,
                variant: variant,
                infestationSize: selectedSize,
                notes: notes.isEmpty ? nil : notes,
                photoFilenames: photoFilenames,
                rangerID: rangerID
            )
            didSave = true
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }
}
