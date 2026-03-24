import Foundation

enum AppConfig {
    static let bundleID = "org.yac.llamarangers"

    // Supabase
    static let supabaseURL: String = {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
    }()
    static let supabaseAnonKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    }()

    // Storage
    static let photosBucket = "lantana-photos"
    static let signedURLExpiry: Int = 3600 // seconds

    // MPC mesh sync
    static let meshServiceType = "yac-lantana"

    // Local photo directory
    static let photosDirectoryName = "Photos"
}
