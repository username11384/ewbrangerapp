import SwiftUI

// MARK: - SpeciesPickerView
// Replaces VariantPickerView. Picks from InvasiveSpecies instead of LantanaVariant.

struct SpeciesPickerView: View {
    @Binding var selectedSpecies: InvasiveSpecies?

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            Text("Species")
                .font(DSFont.headline)
                .foregroundStyle(Color.dsInk)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpace.sm) {
                    ForEach(InvasiveSpecies.allCases.filter { $0 != .unknown }, id: \.self) { species in
                        SpeciesCard(
                            species: species,
                            isSelected: selectedSpecies == species
                        ) {
                            withAnimation(.spring(response: 0.25)) {
                                selectedSpecies = species
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 2)
            }
        }
    }
}

private struct SpeciesCard: View {
    let species: InvasiveSpecies
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DSSpace.sm) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(isSelected ? species.color : species.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: species.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : species.color)
                }
                .overlay(
                    Circle().strokeBorder(
                        isSelected ? species.color : Color.clear,
                        lineWidth: 2
                    )
                )
                .shadow(color: isSelected ? species.color.opacity(0.3) : .clear, radius: 4, y: 2)

                VStack(spacing: 1) {
                    Text(species.displayName)
                        .font(DSFont.badge)
                        .foregroundStyle(isSelected ? species.color : Color.dsInk2)
                        .multilineTextAlignment(.center)
                        .frame(width: 72)
                }
            }
            .padding(.vertical, DSSpace.sm)
            .padding(.horizontal, DSSpace.xs)
            .background(isSelected ? species.color.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - VariantPickerView alias (backward compat for any remaining callers)
// Kept so that existing LogSightingView still compiles while we update it.
private typealias VariantCard = SpeciesCard
