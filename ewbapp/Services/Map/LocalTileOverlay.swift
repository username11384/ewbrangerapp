import MapKit
import Foundation

/// MKTileOverlay subclass that reads map tiles from a bundled MBTiles file (SQLite)
/// or a {z}/{x}/{y}.png directory tree delivered via On-Demand Resources.
final class LocalTileOverlay: MKTileOverlay {

    private var db: OpaquePointer?
    private let tileDirectory: URL?

    /// Initialise with an MBTiles file path.
    init(mbtilesPath: String) {
        self.tileDirectory = nil
        super.init(urlTemplate: nil)
        canReplaceMapContent = true
        openMBTiles(path: mbtilesPath)
    }

    /// Initialise with a directory of {z}/{x}/{y}.png tiles.
    init(tileDirectory: URL) {
        self.tileDirectory = tileDirectory
        super.init(urlTemplate: nil)
        canReplaceMapContent = true
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    // MARK: - Tile loading

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        // Try MBTiles first
        if let db = db {
            let tileData = readFromMBTiles(db: db, z: path.z, x: path.x, y: path.y)
            result(tileData, tileData == nil ? TileError.notFound : nil)
            return
        }

        // Try directory
        if let dir = tileDirectory {
            let fileURL = dir
                .appendingPathComponent("\(path.z)")
                .appendingPathComponent("\(path.x)")
                .appendingPathComponent("\(path.y).png")
            if let data = try? Data(contentsOf: fileURL) {
                result(data, nil)
            } else {
                result(nil, TileError.notFound)
            }
            return
        }

        result(nil, TileError.noSource)
    }

    // MARK: - MBTiles (SQLite)

    private func openMBTiles(path: String) {
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            db = nil
            return
        }
    }

    private func readFromMBTiles(db: OpaquePointer, z: Int, x: Int, y: Int) -> Data? {
        // MBTiles uses TMS y (flipped): tms_y = (1 << z) - 1 - y
        let tmsY = (1 << z) - 1 - y
        var statement: OpaquePointer?
        let sql = "SELECT tile_data FROM tiles WHERE zoom_level=? AND tile_column=? AND tile_row=?"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_int(statement, 1, Int32(z))
        sqlite3_bind_int(statement, 2, Int32(x))
        sqlite3_bind_int(statement, 3, Int32(tmsY))
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        let bytes = sqlite3_column_blob(statement, 0)
        let length = sqlite3_column_bytes(statement, 0)
        guard let bytes = bytes, length > 0 else { return nil }
        return Data(bytes: bytes, count: Int(length))
    }

    enum TileError: Error {
        case notFound
        case noSource
    }
}

import SQLite3
