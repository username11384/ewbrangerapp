import SwiftUI

// MARK: - SpeciesGuideView
// Field guide for all tracked invasive plant species. Replaces VariantGuideView.

struct SpeciesGuideView: View {
    @State private var searchText = ""

    private var filteredSpecies: [InvasiveSpeciesContent.SpeciesInfo] {
        if searchText.isEmpty { return InvasiveSpeciesContent.all }
        return InvasiveSpeciesContent.all.filter {
            $0.commonName.localizedCaseInsensitiveContains(searchText) ||
            $0.scientificName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header summary
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(InvasiveSpeciesContent.all.count) tracked species")
                                .font(DSFont.callout)
                                .foregroundStyle(Color.dsInk2)
                            Text("Cape York Peninsula")
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                        }
                        Spacer()
                        // Category legend
                        HStack(spacing: DSSpace.sm) {
                            ForEach([SpeciesCategory.shrub, .vine, .tree, .grass], id: \.rawValue) { cat in
                                HStack(spacing: 3) {
                                    Image(systemName: cat.iconName)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(Color.dsInk3)
                                    Text(cat.displayName)
                                        .font(DSFont.badge)
                                        .foregroundStyle(Color.dsInk3)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DSSpace.lg)
                    .padding(.vertical, DSSpace.md)

                    Divider().overlay(Color.dsDivider)

                    // Species list
                    LazyVStack(spacing: DSSpace.sm) {
                        ForEach(filteredSpecies, id: \.species) { info in
                            NavigationLink(destination: SpeciesDetailView(info: info)) {
                                SpeciesGuideRow(info: info)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DSSpace.lg)
                    .padding(.top, DSSpace.md)
                    .padding(.bottom, DSSpace.xxl)
                }
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Search species")
            .navigationTitle("Field Guide")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Species Guide Row

private struct SpeciesGuideRow: View {
    let info: InvasiveSpeciesContent.SpeciesInfo

    var priorityColor: Color {
        switch info.priorityLevel {
        case .critical: return .dsStatusActive
        case .high:     return .dsStatusTreat
        case .moderate: return Color(hex: "4A90A4")
        }
    }

    var body: some View {
        HStack(spacing: DSSpace.md) {
            // Species color accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(info.species.color)
                .frame(width: 4, height: 56)

            // Icon + name
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(info.commonName)
                        .font(DSFont.subhead)
                        .foregroundStyle(Color.dsInk)
                    Spacer()
                    // Priority badge
                    Text(info.priorityLevel.rawValue)
                        .font(DSFont.badge)
                        .foregroundStyle(priorityColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.1))
                        .clipShape(Capsule())
                }
                HStack(spacing: 6) {
                    Text(info.scientificName)
                        .font(DSFont.caption)
                        .italic()
                        .foregroundStyle(Color.dsInk3)
                    Spacer()
                    // Category
                    HStack(spacing: 3) {
                        Image(systemName: info.species.category.iconName)
                            .font(.system(size: 10, weight: .medium))
                        Text(info.species.category.displayName)
                            .font(DSFont.badge)
                    }
                    .foregroundStyle(Color.dsInkMuted)
                }
                // Control method pills
                HStack(spacing: 4) {
                    ForEach(info.controlMethods.prefix(3), id: \.self) { method in
                        HStack(spacing: 3) {
                            Image(systemName: method.systemIconName)
                                .font(.system(size: 9, weight: .semibold))
                            Text(method.displayName)
                                .font(DSFont.badge)
                        }
                        .foregroundStyle(Color.dsPrimary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.dsPrimarySoft)
                        .clipShape(Capsule())
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.dsInkMuted)
        }
        .padding(.vertical, DSSpace.sm)
        .padding(.horizontal, DSSpace.md)
        .background(Color.dsCard)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .strokeBorder(Color.dsDivider.opacity(0.6), lineWidth: 0.75)
        )
    }
}
