import SwiftUI

struct SyncStatusBadge: View {
    let status: SyncStatus

    var body: some View {
        Image(systemName: status.iconSystemName)
            .foregroundColor(color)
            .font(.caption)
    }

    private var color: Color {
        switch status {
        case .synced: return .green
        case .pendingCreate, .pendingUpdate: return .orange
        case .pendingDelete: return .red
        }
    }
}
