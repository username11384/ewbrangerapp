import Combine
import Foundation

final class OfflineTileManager: ObservableObject {
    @Published var tileStatus: TileStatus = .checking

    enum TileStatus {
        case checking
        case available(version: String, coverage: String)
        case downloading(progress: Double)
        case unavailable
    }

    static let shared = OfflineTileManager()
    private init() { checkTileAvailability() }

    private func checkTileAvailability() {
        // Check for bundled MBTiles file
        if let path = Bundle.main.path(forResource: "PortStewart", ofType: "mbtiles") {
            tileStatus = .available(version: "bundled", coverage: "Port Stewart ±30km, zoom 10–18")
            return
        }
        // Check ODR downloaded tiles directory
        let tilesDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MapTiles")
        if FileManager.default.fileExists(atPath: tilesDir.path) {
            tileStatus = .available(version: "ODR", coverage: "Port Stewart ±30km, zoom 10–18")
            return
        }
        tileStatus = .unavailable
    }

    func tileOverlay() -> LocalTileOverlay? {
        if let path = Bundle.main.path(forResource: "PortStewart", ofType: "mbtiles") {
            return LocalTileOverlay(mbtilesPath: path)
        }
        let tilesDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MapTiles")
        if FileManager.default.fileExists(atPath: tilesDir.path) {
            return LocalTileOverlay(tileDirectory: tilesDir)
        }
        return nil
    }
}
