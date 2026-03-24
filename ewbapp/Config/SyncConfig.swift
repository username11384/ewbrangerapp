import Foundation

enum SyncConfig {
    // Retry delays in seconds
    static let retryDelay1: TimeInterval = 0          // Immediate
    static let retryDelay2: TimeInterval = 300         // 5 minutes
    static let maxRetryDelay: TimeInterval = 3600      // 1 hour cap
    static let failureThreshold: Int16 = 10           // Show badge after this many failures

    // Chunk sizes for mesh sync
    static let manifestChunkSize = 500                 // Records per manifest chunk
    static let recordChunkSize = 50                    // Records per transfer batch

    // Background sync
    static let backgroundTaskIdentifier = "org.yac.llamarangers.sync"
}
