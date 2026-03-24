import SwiftUI

struct SeasonalAlertBanner: View {
    let alert: SeasonalAlert

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.subheadline.bold())
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(background)
        .cornerRadius(10)
    }

    private var iconName: String {
        switch alert.severity {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch alert.severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private var background: Color {
        switch alert.severity {
        case .info: return Color.blue.opacity(0.1)
        case .warning: return Color.orange.opacity(0.1)
        case .critical: return Color.red.opacity(0.1)
        }
    }
}
