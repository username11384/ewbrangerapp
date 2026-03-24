import SwiftUI
import CoreLocation

struct GPSCaptureView: View {
    let location: CLLocation?
    let accuracyLevel: LocationManager.AccuracyLevel
    let onRecapture: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
            HStack {
                if let location = location {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude))
                            .font(.system(.callout, design: .monospaced))
                        HStack(spacing: 4) {
                            Circle()
                                .fill(accuracyColor)
                                .frame(width: 8, height: 8)
                            Text(String(format: "±%.0fm", location.horizontalAccuracy))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Acquiring GPS…")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button("Re-capture", action: onRecapture)
                    .font(.callout)
                    .buttonStyle(.bordered)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }

    private var accuracyColor: Color {
        switch accuracyLevel {
        case .good: return .green
        case .fair: return .yellow
        case .poor: return .red
        case .unknown: return .gray
        }
    }
}
