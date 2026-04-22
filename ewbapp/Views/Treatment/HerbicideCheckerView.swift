import SwiftUI

// MARK: - HerbicideCheckerView
// Offline herbicide reference and tank-mix compatibility checker.
// All data is static — no network or CoreData required.

struct HerbicideCheckerView: View {

    /// Optional pre-filter: pass the display name of the current sighting species
    /// to immediately filter the list to relevant herbicides.
    var preFilteredSpecies: String?

    @State private var searchText = ""
    @State private var selectedSpeciesFilter: String? = nil
    @State private var selectedHerbicide: Herbicide? = nil
    @State private var showCompatibilityChecker = false

    // MARK: All unique species across all herbicides (for the filter chips)
    private var allSpecies: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for h in HerbicideDatabase.all {
            for s in h.targetSpecies where !seen.contains(s) {
                seen.insert(s)
                result.append(s)
            }
        }
        return result.sorted()
    }

    private var filteredHerbicides: [Herbicide] {
        var list = HerbicideDatabase.all
        if let species = selectedSpeciesFilter {
            list = list.filter { $0.targetSpecies.contains(species) }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.activeIngredient.localizedCaseInsensitiveContains(searchText) ||
                $0.commonProducts.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            speciesFilterBar
            Divider()
            herbicideList
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationTitle("Herbicide Checker")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name or product")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCompatibilityChecker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield")
                        Text("Tank Mix")
                            .font(DSFont.callout)
                    }
                    .foregroundStyle(Color.dsPrimary)
                }
            }
        }
        .sheet(isPresented: $showCompatibilityChecker) {
            TankMixCheckerView()
        }
        .sheet(item: $selectedHerbicide) { herbicide in
            HerbicideDetailView(herbicide: herbicide)
        }
        .onAppear {
            if let species = preFilteredSpecies {
                selectedSpeciesFilter = species
            }
        }
    }

    // MARK: - Species Filter Chips

    private var speciesFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DSSpace.sm) {
                FilterChip(label: "All", isSelected: selectedSpeciesFilter == nil) {
                    selectedSpeciesFilter = nil
                }
                ForEach(allSpecies, id: \.self) { species in
                    FilterChip(label: species, isSelected: selectedSpeciesFilter == species) {
                        selectedSpeciesFilter = selectedSpeciesFilter == species ? nil : species
                    }
                }
            }
            .padding(.horizontal, DSSpace.lg)
            .padding(.vertical, DSSpace.sm)
        }
        .background(Color.dsSurface)
    }

    // MARK: - Herbicide List

    private var herbicideList: some View {
        Group {
            if filteredHerbicides.isEmpty {
                emptyState
            } else {
                List(filteredHerbicides) { herbicide in
                    Button {
                        selectedHerbicide = herbicide
                    } label: {
                        HerbicideRow(herbicide: herbicide)
                    }
                    .listRowBackground(Color.dsBackground)
                    .listRowSeparatorTint(Color.dsDivider)
                }
                .listStyle(.plain)
                .background(Color.dsBackground)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DSSpace.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 42))
                .foregroundStyle(Color.dsInkMuted)
            Text("No herbicides found")
                .font(DSFont.headline)
                .foregroundStyle(Color.dsInk2)
            Text("Try a different species filter or search term.")
                .font(DSFont.callout)
                .foregroundStyle(Color.dsInk3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DSSpace.xl)
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DSFont.callout)
                .foregroundStyle(isSelected ? Color.white : Color.dsInk2)
                .padding(.horizontal, DSSpace.md)
                .padding(.vertical, DSSpace.xs + 2)
                .background(isSelected ? Color.dsPrimary : Color.dsCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.dsPrimary : Color.dsDivider, lineWidth: 1)
                )
        }
    }
}

// MARK: - HerbicideRow

private struct HerbicideRow: View {
    let herbicide: Herbicide

    var body: some View {
        HStack(alignment: .top, spacing: DSSpace.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                    .fill(Color.dsPrimarySoft)
                    .frame(width: 42, height: 42)
                Image(systemName: "drop.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.dsPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(herbicide.name)
                    .font(DSFont.subhead)
                    .foregroundStyle(Color.dsInk)
                Text(herbicide.activeIngredient)
                    .font(DSFont.footnote)
                    .foregroundStyle(Color.dsInk3)
                    .lineLimit(1)
                // Target species pills (up to 3)
                HStack(spacing: DSSpace.xs) {
                    ForEach(herbicide.targetSpecies.prefix(3), id: \.self) { species in
                        Text(species)
                            .font(DSFont.badge)
                            .foregroundStyle(Color.dsPrimary)
                            .padding(.horizontal, DSSpace.sm)
                            .padding(.vertical, 2)
                            .background(Color.dsPrimarySoft)
                            .clipShape(Capsule())
                    }
                    if herbicide.targetSpecies.count > 3 {
                        Text("+\(herbicide.targetSpecies.count - 3)")
                            .font(DSFont.badge)
                            .foregroundStyle(Color.dsInk3)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.dsInkMuted)
                .padding(.top, 4)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - HerbicideDetailView

struct HerbicideDetailView: View {
    let herbicide: Herbicide
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpace.xl) {

                    // Header card
                    headerCard

                    // Target species
                    infoSection(title: "Target Species", icon: "leaf.fill", iconColor: .dsPrimary) {
                        SpeciesPillsView(species: herbicide.targetSpecies)
                    }

                    // Dilution / mixing
                    infoSection(title: "Mixing Instructions", icon: "drop.fill", iconColor: Color(hex: "2E7A6B")) {
                        VStack(alignment: .leading, spacing: DSSpace.sm) {
                            LabeledValue(label: "Foliar dilution", value: "\(String(format: "%.0f", herbicide.dilutionRateMlPer10L)) mL per 10 L water")
                            Divider()
                            Text(herbicide.applicationNotes)
                                .font(DSFont.body)
                                .foregroundStyle(Color.dsInk2)
                        }
                    }

                    // PPE required
                    infoSection(title: "PPE Required", icon: "person.badge.shield.checkmark.fill", iconColor: Color.dsAccent) {
                        VStack(alignment: .leading, spacing: DSSpace.sm) {
                            ForEach(herbicide.ppeRequired, id: \.self) { item in
                                HStack(spacing: DSSpace.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.dsPrimary)
                                        .font(.system(size: 15))
                                    Text(item)
                                        .font(DSFont.body)
                                        .foregroundStyle(Color.dsInk)
                                }
                            }
                        }
                    }

                    // Weather constraints
                    infoSection(title: "Weather & Timing", icon: "cloud.rain.fill", iconColor: Color(hex: "3D6B9A")) {
                        Text(herbicide.weatherConstraints)
                            .font(DSFont.body)
                            .foregroundStyle(Color.dsInk2)
                    }

                    // Incompatibilities
                    if !herbicide.notCompatibleWith.isEmpty {
                        infoSection(title: "Do Not Tank-Mix With", icon: "xmark.shield.fill", iconColor: Color.dsStatusActive) {
                            VStack(alignment: .leading, spacing: DSSpace.sm) {
                                ForEach(herbicide.notCompatibleWith, id: \.self) { name in
                                    HStack(spacing: DSSpace.sm) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Color.dsStatusActive)
                                            .font(.system(size: 15))
                                        Text(name)
                                            .font(DSFont.body)
                                            .foregroundStyle(Color.dsInk)
                                    }
                                }
                            }
                        }
                    } else {
                        infoSection(title: "Tank Mixing", icon: "checkmark.shield.fill", iconColor: Color.dsStatusCleared) {
                            HStack(spacing: DSSpace.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.dsStatusCleared)
                                Text("No known incompatibilities in this database.")
                                    .font(DSFont.body)
                                    .foregroundStyle(Color.dsInk2)
                            }
                        }
                    }

                    // Common products
                    infoSection(title: "Common Products (QLD)", icon: "bag.fill", iconColor: Color.dsInk3) {
                        HStack(spacing: DSSpace.sm) {
                            ForEach(herbicide.commonProducts, id: \.self) { product in
                                Text(product)
                                    .font(DSFont.badge)
                                    .foregroundStyle(Color.dsInk2)
                                    .padding(.horizontal, DSSpace.sm)
                                    .padding(.vertical, 4)
                                    .background(Color.dsSurface)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(Color.dsDivider, lineWidth: 1))
                            }
                        }
                        .flexibleWrapping()
                    }
                }
                .padding(DSSpace.lg)
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle(herbicide.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.dsPrimary)
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(alignment: .center, spacing: DSSpace.lg) {
            ZStack {
                Circle()
                    .fill(Color.dsPrimarySoft)
                    .frame(width: 56, height: 56)
                Image(systemName: "drop.triangle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.dsPrimary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(herbicide.name)
                    .font(DSFont.title)
                    .foregroundStyle(Color.dsInk)
                Text(herbicide.activeIngredient)
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsInk3)
            }
        }
        .modifier(DSCardModifier(padding: DSSpace.lg))
    }

    // MARK: - Generic Info Section

    @ViewBuilder
    private func infoSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.md) {
            HStack(spacing: DSSpace.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
            }
            content()
        }
        .modifier(DSCardModifier(padding: DSSpace.lg))
    }
}

// MARK: - Species Pills

private struct SpeciesPillsView: View {
    let species: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            ForEach(species, id: \.self) { s in
                HStack(spacing: DSSpace.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dsPrimary)
                        .font(.system(size: 15))
                    Text(s)
                        .font(DSFont.body)
                        .foregroundStyle(Color.dsInk)
                }
            }
        }
    }
}

// MARK: - LabeledValue

private struct LabeledValue: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(DSFont.callout)
                .foregroundStyle(Color.dsInk3)
            Spacer()
            Text(value)
                .font(DSFont.callout)
                .foregroundStyle(Color.dsInk)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - FlexibleWrapping layout helper

private struct FlexibleWrappingLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowX: CGFloat = 0
        var totalY: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowX + size.width > maxWidth && rowX > 0 {
                totalY += rowHeight + spacing
                rowX = 0
                rowHeight = 0
            }
            rowX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalY += rowHeight
        return CGSize(width: maxWidth, height: totalY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rowX = bounds.minX
        var rowY = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowX + size.width > bounds.maxX && rowX > bounds.minX {
                rowY += rowHeight + spacing
                rowX = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: rowX, y: rowY), proposal: ProposedViewSize(size))
            rowX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private extension View {
    func flexibleWrapping() -> some View {
        FlexibleWrappingLayout { self }
    }
}

// MARK: - TankMixCheckerView

struct TankMixCheckerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var firstSelection: Herbicide? = nil
    @State private var secondSelection: Herbicide? = nil
    @State private var result: HerbicideDatabase.CompatibilityResult? = nil

    private var allHerbicides: [Herbicide] { HerbicideDatabase.all }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DSSpace.xl) {
                        instructionCard
                        selectionSection
                        if let result = result {
                            resultCard(result)
                        }
                    }
                    .padding(DSSpace.lg)
                }

                // Check button fixed at bottom
                checkButton
                    .padding(.horizontal, DSSpace.lg)
                    .padding(.bottom, DSSpace.xl)
                    .padding(.top, DSSpace.md)
                    .background(Color.dsBackground)
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle("Tank-Mix Checker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.dsPrimary)
                }
            }
        }
    }

    // MARK: - Instruction Card

    private var instructionCard: some View {
        HStack(alignment: .top, spacing: DSSpace.md) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.dsPrimary)
                .font(.system(size: 18))
            Text("Select two herbicides to check whether they can be safely combined in the same tank mix. Never mix herbicides not listed as compatible.")
                .font(DSFont.callout)
                .foregroundStyle(Color.dsInk2)
        }
        .modifier(DSCardModifier(padding: DSSpace.lg))
    }

    // MARK: - Selection Pickers

    private var selectionSection: some View {
        VStack(spacing: DSSpace.lg) {
            herbicidePicker(label: "First Herbicide", selection: $firstSelection)
            herbicidePicker(label: "Second Herbicide", selection: $secondSelection)
        }
    }

    private func herbicidePicker(label: String, selection: Binding<Herbicide?>) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            Text(label)
                .font(DSFont.callout)
                .foregroundStyle(Color.dsInk3)
                .padding(.horizontal, 2)
            Menu {
                Button("None selected") { selection.wrappedValue = nil }
                Divider()
                ForEach(allHerbicides) { herbicide in
                    Button(herbicide.name) { selection.wrappedValue = herbicide }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue?.name ?? "Tap to select…")
                        .font(DSFont.subhead)
                        .foregroundStyle(selection.wrappedValue == nil ? Color.dsInkMuted : Color.dsInk)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.dsInk3)
                }
                .padding(DSSpace.md)
                .background(Color.dsCard)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .strokeBorder(Color.dsDivider, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Check Button

    private var checkButton: some View {
        Button {
            guard let a = firstSelection, let b = secondSelection else { return }
            result = HerbicideDatabase.compatibility(between: a, and: b)
        } label: {
            HStack(spacing: DSSpace.sm) {
                Image(systemName: "checkmark.shield.fill")
                Text("Check Compatibility")
                    .font(DSFont.subhead)
            }
            .frame(maxWidth: .infinity)
            .padding(DSSpace.md)
            .background(firstSelection != nil && secondSelection != nil ? Color.dsPrimary : Color.dsInkMuted)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
        }
        .disabled(firstSelection == nil || secondSelection == nil)
    }

    // MARK: - Result Card

    @ViewBuilder
    private func resultCard(_ compatResult: HerbicideDatabase.CompatibilityResult) -> some View {
        switch compatResult {
        case .compatible:
            ResultBanner(
                icon: "checkmark.circle.fill",
                iconColor: Color.dsStatusCleared,
                background: Color.dsStatusClearedSoft,
                border: Color.dsStatusCleared,
                title: "Compatible",
                message: "These two herbicides can be tank-mixed. Always follow label rates and mix fresh. Test a small sample first if you are unsure about your water quality."
            )
        case .incompatible:
            ResultBanner(
                icon: "xmark.circle.fill",
                iconColor: Color.dsStatusActive,
                background: Color.dsStatusActiveSoft,
                border: Color.dsStatusActive,
                title: "Incompatible — Do Not Mix",
                message: "These herbicides should NOT be combined in the same tank. Mixing them may reduce effectiveness, cause chemical reactions, or create safety hazards. Apply separately."
            )
        case .sameProduct:
            ResultBanner(
                icon: "exclamationmark.triangle.fill",
                iconColor: Color.dsStatusTreat,
                background: Color.dsStatusTreatSoft,
                border: Color.dsStatusTreat,
                title: "Same Herbicide Selected",
                message: "You have selected the same herbicide twice. Please choose two different herbicides to check compatibility."
            )
        }
    }
}

// MARK: - ResultBanner

private struct ResultBanner: View {
    let icon: String
    let iconColor: Color
    let background: Color
    let border: Color
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: DSSpace.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: DSSpace.sm) {
                Text(title)
                    .font(DSFont.headline)
                    .foregroundStyle(iconColor)
                Text(message)
                    .font(DSFont.body)
                    .foregroundStyle(Color.dsInk2)
            }
        }
        .padding(DSSpace.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .strokeBorder(border.opacity(0.5), lineWidth: 1)
        )
    }
}
