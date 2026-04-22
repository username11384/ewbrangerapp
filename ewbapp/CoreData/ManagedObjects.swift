import CoreData
import Foundation

// MARK: - InfestationZone

@objc(InfestationZone)
public class InfestationZone: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var name: String?
    @NSManaged public var status: String?
    @NSManaged public var dominantVariant: String?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var sightings: NSSet?
    @NSManaged public var snapshots: NSOrderedSet?
}

// MARK: - InfestationZoneSnapshot

@objc(InfestationZoneSnapshot)
public class InfestationZoneSnapshot: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var snapshotDate: Date?
    @NSManaged public var polygonCoordinates: NSArray?
    @NSManaged public var area: Double
    @NSManaged public var createdByRangerID: UUID?
    @objc(zone) @NSManaged public var parentZone: InfestationZone?
}

// MARK: - PatrolRecord

@objc(PatrolRecord)
public class PatrolRecord: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var patrolDate: Date?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var areaName: String?
    @NSManaged public var checklistItems: NSData?
    @NSManaged public var notes: String?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var ranger: RangerProfile?
}

// MARK: - PesticideStock

@objc(PesticideStock)
public class PesticideStock: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var productName: String?
    @NSManaged public var unit: String?
    @NSManaged public var currentQuantity: Double
    @NSManaged public var minThreshold: Double
    @NSManaged public var syncStatus: Int16
    @NSManaged public var usageRecords: NSSet?
}

// MARK: - PesticideUsageRecord

@objc(PesticideUsageRecord)
public class PesticideUsageRecord: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var usedQuantity: Double
    @NSManaged public var usedAt: Date?
    @NSManaged public var notes: String?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var stock: PesticideStock?
    @NSManaged public var treatment: TreatmentRecord?
    @NSManaged public var ranger: RangerProfile?
}

// MARK: - RangerProfile

@objc(RangerProfile)
public class RangerProfile: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var supabaseUID: String?
    @NSManaged public var displayName: String?
    @NSManaged public var role: String?
    @NSManaged public var isCurrentDevice: Bool
    @NSManaged public var avatarFilename: String?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var sightings: NSSet?
    @NSManaged public var treatmentRecords: NSSet?
    @NSManaged public var patrolRecords: NSSet?
    @NSManaged public var pesticideUsageRecords: NSSet?
    @NSManaged public var tasks: NSSet?
}

// MARK: - SightingLog

@objc(SightingLog)
public class SightingLog: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var horizontalAccuracy: Double
    @NSManaged public var variant: String?
    @NSManaged public var infestationSize: String?
    @NSManaged public var infestationAreaEstimate: String?
    @NSManaged public var notes: String?
    @NSManaged public var photoFilenames: NSArray?
    @NSManaged public var deviceID: String?
    @NSManaged public var serverID: String?
    @NSManaged public var voiceNotePath: String?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var ranger: RangerProfile?
    @NSManaged public var infestationZone: InfestationZone?
    @NSManaged public var treatmentRecords: NSSet?
}

// MARK: - SyncQueue

@objc(SyncQueue)
public class SyncQueue: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @objc(entityName) @NSManaged public var entityTypeName: String?
    @NSManaged public var entityID: UUID
    @NSManaged public var operationType: String?
    @NSManaged public var payload: Data?
    @NSManaged public var attemptCount: Int16
    @NSManaged public var lastAttemptAt: Date?
    @NSManaged public var lastErrorMessage: String?
}

// MARK: - TreatmentFollowUp

@objc(TreatmentFollowUp)
public class TreatmentFollowUp: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var followUpDate: Date?
    @NSManaged public var percentDead: Double
    @NSManaged public var regrowthLevel: String?
    @NSManaged public var notes: String?
    @NSManaged public var photoPath: String?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var treatment: TreatmentRecord?
}

extension TreatmentFollowUp: Identifiable {}

extension TreatmentFollowUp {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TreatmentFollowUp> {
        return NSFetchRequest<TreatmentFollowUp>(entityName: "TreatmentFollowUp")
    }
}

// MARK: - TreatmentRecord

@objc(TreatmentRecord)
public class TreatmentRecord: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var treatmentDate: Date?
    @NSManaged public var method: String?
    @NSManaged public var herbicideProduct: String?
    @NSManaged public var outcomeNotes: String?
    @NSManaged public var followUpDate: Date?
    @NSManaged public var photoFilenames: NSArray?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var sighting: SightingLog?
    @NSManaged public var ranger: RangerProfile?
    @NSManaged public var pesticideUsageRecords: NSSet?
    @NSManaged public var followUpTask: RangerTask?
    @NSManaged public var followUps: NSSet?
}

// MARK: - RangerTask

@objc(RangerTask)
public class RangerTask: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var title: String?
    @NSManaged public var notes: String?
    @NSManaged public var priority: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var isComplete: Bool
    @NSManaged public var completedAt: Date?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var assignedRanger: RangerProfile?
    @NSManaged public var sourceTreatment: TreatmentRecord?
}

extension RangerTask: Identifiable {}

// MARK: - HazardLog

@objc(HazardLog)
public class HazardLog: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var title: String?
    @NSManaged public var hazardType: String?
    @NSManaged public var severity: String?
    @NSManaged public var notes: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var photoPath: String?
    @NSManaged public var syncedToCloud: Bool
}

extension HazardLog: Identifiable {}

// MARK: - NSFetchRequest convenience

extension HazardLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HazardLog> {
        return NSFetchRequest<HazardLog>(entityName: "HazardLog")
    }
}

extension InfestationZone {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InfestationZone> {
        return NSFetchRequest<InfestationZone>(entityName: "InfestationZone")
    }
}
extension InfestationZoneSnapshot {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InfestationZoneSnapshot> {
        return NSFetchRequest<InfestationZoneSnapshot>(entityName: "InfestationZoneSnapshot")
    }
}
extension PatrolRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PatrolRecord> {
        return NSFetchRequest<PatrolRecord>(entityName: "PatrolRecord")
    }
}
extension PesticideStock {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PesticideStock> {
        return NSFetchRequest<PesticideStock>(entityName: "PesticideStock")
    }
}
extension PesticideUsageRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PesticideUsageRecord> {
        return NSFetchRequest<PesticideUsageRecord>(entityName: "PesticideUsageRecord")
    }
}
extension RangerTask {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RangerTask> {
        return NSFetchRequest<RangerTask>(entityName: "RangerTask")
    }
}
extension RangerProfile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RangerProfile> {
        return NSFetchRequest<RangerProfile>(entityName: "RangerProfile")
    }
}
extension SightingLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SightingLog> {
        return NSFetchRequest<SightingLog>(entityName: "SightingLog")
    }
}
extension SyncQueue {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SyncQueue> {
        return NSFetchRequest<SyncQueue>(entityName: "SyncQueue")
    }
}
extension TreatmentRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TreatmentRecord> {
        return NSFetchRequest<TreatmentRecord>(entityName: "TreatmentRecord")
    }
}

// MARK: - Equipment

@objc(Equipment)
public class Equipment: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var name: String?
    @NSManaged public var equipmentType: String?
    @NSManaged public var serialNumber: String?
    @NSManaged public var notes: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var lastMaintenanceDate: Date?
    @NSManaged public var nextMaintenanceDue: Date?
    @NSManaged public var maintenanceRecords: NSSet?
}

// MARK: - MaintenanceRecord

@objc(MaintenanceRecord)
public class MaintenanceRecord: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var equipmentID: UUID?
    @NSManaged public var maintenanceType: String
    @NSManaged public var descriptionText: String
    @NSManaged public var performedBy: String
    @NSManaged public var costAmount: Double
    @NSManaged public var date: Date
    @NSManaged public var equipment: Equipment?
}

// MARK: - Identifiable conformances for SwiftUI

extension SightingLog: Identifiable {}
extension PatrolRecord: Identifiable {}
extension PesticideStock: Identifiable {}
extension PesticideUsageRecord: Identifiable {}
extension RangerProfile: Identifiable {}
extension TreatmentRecord: Identifiable {}
extension InfestationZone: Identifiable {}
extension Equipment: Identifiable {}
extension MaintenanceRecord: Identifiable {}

// MARK: - @unchecked Sendable — NSManagedObject subclasses are not Sendable by default,
// but all cross-context access in this app goes through performAndWait / perform blocks.

extension SightingLog: @unchecked Sendable {}
extension TreatmentRecord: @unchecked Sendable {}
extension TreatmentFollowUp: @unchecked Sendable {}
extension RangerTask: @unchecked Sendable {}
extension RangerProfile: @unchecked Sendable {}
extension PatrolRecord: @unchecked Sendable {}
extension PesticideStock: @unchecked Sendable {}
extension PesticideUsageRecord: @unchecked Sendable {}
extension InfestationZone: @unchecked Sendable {}
extension InfestationZoneSnapshot: @unchecked Sendable {}
extension SyncQueue: @unchecked Sendable {}
extension Equipment: @unchecked Sendable {}
extension MaintenanceRecord: @unchecked Sendable {}
extension HazardLog: @unchecked Sendable {}

extension Equipment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Equipment> {
        return NSFetchRequest<Equipment>(entityName: "Equipment")
    }
}
extension MaintenanceRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MaintenanceRecord> {
        return NSFetchRequest<MaintenanceRecord>(entityName: "MaintenanceRecord")
    }
}
