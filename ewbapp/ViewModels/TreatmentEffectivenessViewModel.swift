import Combine
import CoreData
import Foundation

// MARK: - Treatment Effectiveness Summary

struct TreatmentEffectivenessSummary {
    /// Number of follow-up assessments recorded for this sighting
    let followUpCount: Int
    /// Average percentage of plants dead across all follow-ups (0–100)
    let avgPercentDead: Double
    /// The most recently recorded regrowth level, or nil if no follow-ups
    let latestRegrowthLevel: RegrowthLevel?
    /// Qualitative success category derived from avgPercentDead
    var successCategory: SuccessCategory {
        switch avgPercentDead {
        case 80...: return .high
        case 50..<80: return .moderate
        case 20..<50: return .low
        default: return .minimal
        }
    }

    enum SuccessCategory: String {
        case high     = "High"
        case moderate = "Moderate"
        case low      = "Low"
        case minimal  = "Minimal"

        var color: String {
            switch self {
            case .high:     return "dsStatusCleared"
            case .moderate: return "dsPrimary"
            case .low:      return "dsAccent"
            case .minimal:  return "dsStatusActive"
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class TreatmentEffectivenessViewModel: ObservableObject {
    @Published var followUps: [TreatmentFollowUp] = []
    @Published var isSaving: Bool = false

    private let persistence: PersistenceController
    let sighting: SightingLog

    init(sighting: SightingLog, persistence: PersistenceController) {
        self.sighting = sighting
        self.persistence = persistence
        loadFollowUps()
    }

    // MARK: - Load

    func loadFollowUps() {
        let context = persistence.mainContext
        // Gather all treatment IDs for this sighting, then fetch follow-ups
        let treatments = (sighting.treatmentRecords as? Set<TreatmentRecord>) ?? []
        guard !treatments.isEmpty else {
            followUps = []
            return
        }
        let treatmentObjectIDs = treatments.map(\.objectID)
        do {
            let request = TreatmentFollowUp.fetchRequest()
            request.predicate = NSPredicate(format: "treatment IN %@", treatments)
            request.sortDescriptors = [NSSortDescriptor(key: "followUpDate", ascending: false)]
            followUps = try context.fetch(request)
        } catch {
            print("[TreatmentEffectivenessVM] fetch error: \(error)")
            followUps = []
        }
        _ = treatmentObjectIDs // suppress unused warning
    }

    // MARK: - Save a new follow-up

    func saveFollowUp(
        for treatment: TreatmentRecord,
        followUpDate: Date,
        percentDead: Double,
        regrowthLevel: RegrowthLevel,
        notes: String?,
        photoPath: String?
    ) async {
        isSaving = true
        defer { isSaving = false }
        let context = persistence.backgroundContext
        let treatmentID = treatment.objectID
        await context.perform {
            let followUp = TreatmentFollowUp(context: context)
            followUp.id = UUID()
            followUp.followUpDate = followUpDate
            followUp.percentDead = percentDead
            followUp.regrowthLevel = regrowthLevel.rawValue
            followUp.notes = notes?.isEmpty == false ? notes : nil
            followUp.photoPath = photoPath
            followUp.syncStatus = SyncStatus.pendingCreate.rawValue
            if let treatmentObj = context.object(with: treatmentID) as? TreatmentRecord {
                followUp.treatment = treatmentObj
            }
            try? context.save()
        }
        loadFollowUps()
    }

    // MARK: - Summary Statistics

    var summary: TreatmentEffectivenessSummary {
        let count = followUps.count
        let avgDead = count > 0
            ? followUps.reduce(0.0) { $0 + $1.percentDead } / Double(count)
            : 0.0
        let latestRegrowth = followUps.first
            .flatMap { RegrowthLevel(rawValue: $0.regrowthLevel ?? "") }
        return TreatmentEffectivenessSummary(
            followUpCount: count,
            avgPercentDead: avgDead,
            latestRegrowthLevel: latestRegrowth
        )
    }

    // MARK: - Follow-up due badge

    /// Returns true if any treatment was applied 2+ weeks ago and has no follow-up recorded.
    var isFollowUpDue: Bool {
        let treatments = (sighting.treatmentRecords as? Set<TreatmentRecord>) ?? []
        let twoWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date()
        for treatment in treatments {
            guard let date = treatment.treatmentDate, date <= twoWeeksAgo else { continue }
            let hasFollowUp = followUps.contains { $0.treatment?.objectID == treatment.objectID }
            if !hasFollowUp { return true }
        }
        return false
    }

    /// The most recent treatment for this sighting (used to pre-select in the form).
    var latestTreatment: TreatmentRecord? {
        ((sighting.treatmentRecords as? Set<TreatmentRecord>) ?? [])
            .sorted { ($0.treatmentDate ?? .distantPast) > ($1.treatmentDate ?? .distantPast) }
            .first
    }
}
