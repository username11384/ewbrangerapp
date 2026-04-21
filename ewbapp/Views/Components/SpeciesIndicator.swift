import SwiftUI

// MARK: - SpeciesIndicator
// Replaces VariantColourDot. Shows a species color circle with optional icon.

struct SpeciesIndicator: View {
    let species: InvasiveSpecies
    var size: CGFloat = 12
    var showIcon: Bool = false

    var body: some View {
        if showIcon {
            ZStack {
                Circle()
                    .fill(species.color)
                    .frame(width: size, height: size)
                Image(systemName: species.iconName)
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(.white)
            }
        } else {
            Circle()
                .fill(species.color)
                .frame(width: size, height: size)
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5))
        }
    }
}

// MARK: - SpeciesBadge
// Pill badge: colored icon dot + species display name

struct SpeciesBadge: View {
    let species: InvasiveSpecies
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            SpeciesIndicator(species: species, size: compact ? 8 : 10)
            Text(species.displayName)
                .font(compact ? DSFont.badge : DSFont.callout)
                .foregroundStyle(species.color)
        }
        .padding(.horizontal, compact ? 7 : DSSpace.sm)
        .padding(.vertical, compact ? 2 : 4)
        .background(species.color.opacity(0.1))
        .clipShape(Capsule())
    }
}
