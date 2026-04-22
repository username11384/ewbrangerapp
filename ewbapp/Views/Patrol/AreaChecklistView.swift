import SwiftUI

// MARK: - AreaChecklistView

/// Shows a per-area custom checklist for the current patrol.
/// Rangers tick off items during the patrol. State is in-memory and resets each session.
struct AreaChecklistView: View {
    @StateObject private var checklistVM = PatrolChecklistViewModel()
    let areaName: String

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                progressHeader
                    .padding(.horizontal, DSSpace.lg)
                    .padding(.top, DSSpace.lg)
                    .padding(.bottom, DSSpace.md)

                if checklistVM.states.isEmpty {
                    DSEmptyState(
                        icon: "checklist",
                        title: "No Items",
                        message: "No checklist items are defined for this area."
                    )
                } else {
                    categoryList
                }
            }
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationTitle("Area Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checklistVM.load(for: areaName)
        }
        .onChange(of: areaName) { _, newArea in
            checklistVM.load(for: newArea)
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsPrimary)
                Text(areaName)
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
                Spacer()
                Text("\(checklistVM.completedCount)/\(checklistVM.totalCount)")
                    .font(DSFont.badge)
                    .foregroundStyle(checklistVM.completedCount == checklistVM.totalCount ? Color.dsStatusCleared : Color.dsInk3)
                    .padding(.horizontal, DSSpace.sm)
                    .padding(.vertical, 4)
                    .background(
                        checklistVM.completedCount == checklistVM.totalCount
                            ? Color.dsStatusClearedSoft
                            : Color.dsSurface
                    )
                    .clipShape(Capsule())
            }

            ProgressView(value: checklistVM.completionFraction)
                .tint(checklistVM.completedCount == checklistVM.totalCount ? Color.dsStatusCleared : Color.dsPrimary)
                .animation(.easeInOut(duration: 0.3), value: checklistVM.completionFraction)

            Text(progressLabel)
                .font(DSFont.caption)
                .foregroundStyle(Color.dsInk3)
        }
        .dsCard()
    }

    private var progressLabel: String {
        let remaining = checklistVM.totalCount - checklistVM.completedCount
        if remaining == 0 {
            return "All items complete"
        } else if remaining == 1 {
            return "1 item remaining"
        } else {
            return "\(remaining) items remaining"
        }
    }

    // MARK: - Category Sections

    private var categoryList: some View {
        VStack(spacing: DSSpace.md) {
            ForEach(checklistVM.categories, id: \.self) { category in
                categorySection(category)
            }
        }
        .padding(.horizontal, DSSpace.lg)
        .padding(.bottom, DSSpace.xl)
    }

    private func categorySection(_ category: String) -> some View {
        let sectionStates = checklistVM.states(for: category)
        let completedInSection = sectionStates.filter(\.isChecked).count

        return VStack(alignment: .leading, spacing: DSSpace.xs) {
            // Section header
            HStack {
                Image(systemName: categoryIcon(for: category))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(categoryColor(for: category))
                Text(category.uppercased())
                    .font(DSFont.badge)
                    .foregroundStyle(categoryColor(for: category))
                    .tracking(0.8)
                Spacer()
                Text("\(completedInSection)/\(sectionStates.count)")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk3)
            }
            .padding(.horizontal, DSSpace.sm)
            .padding(.top, DSSpace.sm)

            // Items
            VStack(spacing: 0) {
                ForEach(sectionStates) { state in
                    AreaChecklistItemRow(
                        state: state,
                        onToggle: { checklistVM.toggle(id: state.id) }
                    )

                    if state.id != sectionStates.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Color.dsCard)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .strokeBorder(Color.dsDivider.opacity(0.6), lineWidth: 0.75)
            )
            .shadow(color: Color.dsInk.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Category Helpers

    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Safety":        return .dsStatusActive
        case "Weed":          return .dsSpeciesLantana
        case "Wildlife":      return .dsStatusCleared
        case "Infrastructure": return .dsInk2
        default:              return .dsInk3
        }
    }

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Safety":         return "exclamationmark.shield.fill"
        case "Weed":           return "leaf.fill"
        case "Wildlife":       return "hare.fill"
        case "Infrastructure": return "wrench.and.screwdriver.fill"
        default:               return "tag.fill"
        }
    }
}

// MARK: - AreaChecklistItemRow

private struct AreaChecklistItemRow: View {
    let state: ChecklistItemState
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: DSSpace.md) {
                Image(systemName: state.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(state.isChecked ? Color.dsPrimary : Color.dsInkMuted)
                    .animation(.spring(duration: 0.25), value: state.isChecked)

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.item.title)
                        .font(DSFont.body)
                        .foregroundStyle(state.isChecked ? Color.dsInk3 : Color.dsInk)
                        .strikethrough(state.isChecked, color: Color.dsInk3)
                        .animation(.easeInOut(duration: 0.2), value: state.isChecked)

                    if let checkedAt = state.checkedAt {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.dsStatusCleared)
                            Text(checkedAt, style: .time)
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, DSSpace.md)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
