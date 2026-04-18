import SwiftUI

struct MapActionCardData {
    let title: String
    let subtitle: String?
    let zone: String?
    let ranger: String?
    let accent: Color
    let statusLabel: String?
    let anchor: CGPoint
    let primary: MapCardAction?
    let secondary: MapCardAction?
}

struct MapCardAction {
    let label: String
    let icon: String
    let isDestructive: Bool
    let handler: () -> Void
}

private let cardWidth: CGFloat = 260
private let arrowSize: CGFloat = 10
private let pinOffset: CGFloat = 52

struct MapActionCard: View {
    let data: MapActionCardData
    let screenSize: CGSize
    let dismiss: () -> Void

    private var cardX: CGFloat {
        let half = cardWidth / 2
        return min(max(data.anchor.x, half + 12), screenSize.width - half - 12)
    }

    private var estimatedHeight: CGFloat {
        var h: CGFloat = 16 + 44 + 16
        if data.primary != nil || data.secondary != nil { h += 44 + 12 }
        if data.zone != nil || data.ranger != nil || data.subtitle != nil { h += 18 }
        return h
    }

    private var showAbove: Bool {
        data.anchor.y - pinOffset - estimatedHeight > 24
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                if !showAbove {
                    arrow(up: true)
                }
                cardBody
                if showAbove {
                    arrow(up: false)
                }
            }
            .frame(width: cardWidth)
            .position(
                x: cardX,
                y: showAbove
                    ? data.anchor.y - pinOffset - estimatedHeight / 2
                    : data.anchor.y + pinOffset + estimatedHeight / 2
            )
        }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(data.accent.opacity(0.18))
                    Circle().stroke(data.accent, lineWidth: 1.2)
                    Circle().fill(data.accent).frame(width: 12, height: 12)
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(data.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.ink)
                        .lineLimit(1)
                    if let sub = data.subtitle {
                        Text(sub)
                            .font(.system(size: 12))
                            .foregroundColor(.ink3)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if let status = data.statusLabel {
                    Text(status.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(statusTextColor(status))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(statusBackground(status))
                        .clipShape(Capsule())
                }
            }

            if data.zone != nil || data.ranger != nil {
                VStack(alignment: .leading, spacing: 3) {
                    if let zone = data.zone {
                        metaRow(icon: "square.dashed", text: zone)
                    }
                    if let ranger = data.ranger {
                        metaRow(icon: "person.fill", text: ranger)
                    }
                }
            }

            if data.primary != nil || data.secondary != nil {
                HStack(spacing: 8) {
                    if let primary = data.primary {
                        Button {
                            primary.handler()
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Text(primary.label)
                                    .font(.system(size: 14, weight: .semibold))
                                Image(systemName: primary.icon)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.euc)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.eucSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    if let secondary = data.secondary {
                        Button {
                            secondary.handler()
                            dismiss()
                        } label: {
                            Image(systemName: secondary.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(secondary.isDestructive ? .statusActive : .ink2)
                                .frame(width: 40, height: 40)
                                .background(Color.paperDeep.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Color.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lineBase.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 14, y: 6)
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.ink3)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.ink2)
                .lineLimit(1)
        }
    }

    private func arrow(up: Bool) -> some View {
        ArrowTip(pointingDown: !up)
            .fill(Color.card)
            .frame(width: arrowSize * 2, height: arrowSize)
            .offset(x: data.anchor.x - cardX)
            .shadow(color: Color.black.opacity(0.08), radius: 2, y: up ? -1 : 1)
    }

    private func statusTextColor(_ label: String) -> Color {
        switch label.lowercased() {
        case "treating": return .statusTreat
        case "cleared": return .statusCleared
        case "active": return .statusActive
        case "completed": return .statusCleared
        default: return .ink2
        }
    }

    private func statusBackground(_ label: String) -> Color {
        switch label.lowercased() {
        case "treating": return .statusTreatSoft
        case "cleared": return .statusClearedSoft
        case "active": return .statusActiveSoft
        case "completed": return .statusClearedSoft
        default: return .paperDeep
        }
    }
}

private struct ArrowTip: Shape {
    let pointingDown: Bool
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if pointingDown {
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        } else {
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        p.closeSubpath()
        return p
    }
}
