import SwiftUI

struct MapActionCardData {
    let title: String
    let subtitle: String?
    let anchor: CGPoint   // screen-space tip of the pin / tap point
    let actions: [MapCardAction]
}

struct MapCardAction {
    let label: String
    let icon: String
    let isDestructive: Bool
    let handler: () -> Void
}

private let cardWidth: CGFloat = 190
private let cardHeight: CGFloat = 44   // approximate per-row height
private let arrowSize: CGFloat = 8
private let pinOffset: CGFloat = 50    // pts above the coordinate tip to clear the marker

struct MapActionCard: View {
    let data: MapActionCardData
    let screenSize: CGSize
    let dismiss: () -> Void

    private var totalHeight: CGFloat {
        let rows = CGFloat(data.actions.count)
        let headerHeight: CGFloat = data.subtitle != nil ? 52 : 36
        return headerHeight + rows * cardHeight + arrowSize
    }

    /// X position clamped so the card stays on screen
    private var cardX: CGFloat {
        let half = cardWidth / 2
        return min(max(data.anchor.x, half + 8), screenSize.width - half - 8)
    }

    /// Card appears above the pin; flip below if too close to top
    private var showAbove: Bool {
        data.anchor.y - pinOffset - totalHeight > 8
    }

    private var cardY: CGFloat {
        showAbove
            ? data.anchor.y - pinOffset - totalHeight / 2
            : data.anchor.y + pinOffset + totalHeight / 2
    }

    var body: some View {
        ZStack {
            // Dismiss on background tap
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }

            cardBody
                .position(x: cardX, y: cardY)
        }
    }

    private var cardBody: some View {
        VStack(spacing: 0) {
            // Arrow pointing toward pin
            if showAbove {
                Spacer()
                arrowShape(pointingDown: true)
            } else {
                arrowShape(pointingDown: false)
                Spacer()
            }
        }
        .frame(width: cardWidth, height: totalHeight)
        .overlay(
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 2) {
                    Text(data.title)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    if let sub = data.subtitle {
                        Text(sub)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                // Actions
                ForEach(data.actions.indices, id: \.self) { i in
                    Button {
                        data.actions[i].handler()
                        dismiss()
                    } label: {
                        Label(data.actions[i].label, systemImage: data.actions[i].icon)
                            .font(.subheadline)
                            .foregroundColor(data.actions[i].isDestructive ? .red : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if i < data.actions.count - 1 { Divider() }
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            // Leave room for the arrow
            .padding(showAbove ? .bottom : .top, arrowSize)
        )
    }

    @ViewBuilder
    private func arrowShape(pointingDown: Bool) -> some View {
        ArrowTip(pointingDown: pointingDown)
            .fill(.regularMaterial)
            .frame(width: arrowSize * 2, height: arrowSize)
            .offset(x: data.anchor.x - cardX)   // align arrow with pin horizontally
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
