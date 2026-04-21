import SwiftUI

struct SeasonalAlertBanner: View {
    let alert: SeasonalAlert

    var body: some View {
        HStack(alignment: .top, spacing: DSSpace.md) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .font(.system(size: 18, weight: .semibold))
            VStack(alignment: .leading, spacing: DSSpace.xs) {
                Text(alert.title)
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsInk)
                Text(alert.message)
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk2)
            }
            Spacer()
        }
        .padding(DSSpace.md)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .strokeBorder(iconColor.opacity(0.2), lineWidth: 0.75)
        )
    }

    private var iconName: String {
        switch alert.severity {
        case .info:     return "info.circle.fill"
        case .warning:  return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch alert.severity {
        case .info:     return Color(hex: "4A90A4")
        case .warning:  return Color.dsStatusTreat
        case .critical: return Color.dsStatusActive
        }
    }

    private var background: Color {
        switch alert.severity {
        case .info:     return Color(hex: "4A90A4").opacity(0.08)
        case .warning:  return Color.dsStatusTreatSoft
        case .critical: return Color.dsStatusActiveSoft
        }
    }
}
