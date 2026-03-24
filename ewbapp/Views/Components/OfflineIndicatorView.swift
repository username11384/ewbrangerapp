import SwiftUI

struct OfflineIndicatorView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.caption)
            Text("Offline — data saved locally")
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange)
        .cornerRadius(20)
    }
}
