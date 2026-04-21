import SwiftUI
import UIKit

// MARK: - SpeciesDetailView
// Detailed field guide entry for a single invasive species. Replaces VariantDetailView.

struct SpeciesDetailView: View {
    let info: InvasiveSpeciesContent.SpeciesInfo

    private var headerTextColor: Color {
        let uiColor = UIColor(info.species.color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.65 ? Color(uiColor: .label) : .white
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero header
                speciesHeader

                VStack(alignment: .leading, spacing: DSSpace.xl) {
                    // Biocontrol warning
                    if info.species.hasBiocontrolConcern {
                        SeasonalAlertBanner(alert: SeasonalAlert(
                            title: "Check for Biocontrol Insects",
                            message: "During the wet season (Nov–Mar), check for lantana bug (Aconophora compressa) before applying chemicals. Biocontrol insects must be protected.",
                            severity: .warning
                        ))
                    }

                    // Identifying features
                    fieldSection(title: "Identifying Features", icon: "magnifyingglass") {
                        Text(info.identifyingFeatures)
                            .font(DSFont.body)
                            .foregroundStyle(Color.dsInk2)
                    }

                    // Control methods
                    fieldSection(title: "Control Methods", icon: "checkmark.shield.fill") {
                        VStack(spacing: DSSpace.sm) {
                            ForEach(info.controlMethods, id: \.self) { method in
                                ControlMethodRow(method: method)
                            }
                        }
                    }

                    // Seasonal notes
                    if let seasonal = info.seasonalNotes {
                        fieldSection(title: "Seasonal Notes", icon: "calendar") {
                            Text(seasonal)
                                .font(DSFont.body)
                                .foregroundStyle(Color.dsInk2)
                        }
                    }

                    // Priority level
                    HStack(spacing: DSSpace.sm) {
                        Text("Priority:")
                            .font(DSFont.callout)
                            .foregroundStyle(Color.dsInk3)
                        Text(info.priorityLevel.rawValue)
                            .font(DSFont.callout)
                            .foregroundStyle(priorityColor)
                            .fontWeight(.semibold)
                    }
                    .padding(.bottom, DSSpace.xxl)
                }
                .padding(.horizontal, DSSpace.lg)
                .padding(.top, DSSpace.xl)
            }
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationTitle(info.commonName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    @ViewBuilder
    private var speciesHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Background: gradient from species color
            LinearGradient(
                colors: [info.species.color, info.species.color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity)
            .frame(height: 200)

            // Optional photo
            if let imageName = info.imageName, let img = UIImage(named: imageName) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.4), .black.opacity(0.05)],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
            }

            // Overlay: name + scientific name
            VStack(alignment: .leading, spacing: 4) {
                Text(info.commonName)
                    .font(DSFont.title)
                    .foregroundStyle(headerTextColor)
                Text(info.scientificName)
                    .font(DSFont.body.italic())
                    .foregroundStyle(headerTextColor.opacity(0.8))
                // Category chip
                HStack(spacing: 4) {
                    Image(systemName: info.species.category.iconName)
                        .font(.system(size: 11, weight: .semibold))
                    Text(info.species.category.displayName)
                        .font(DSFont.badge)
                }
                .foregroundStyle(headerTextColor.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .padding(DSSpace.lg)
        }
    }

    // MARK: - Section helper

    @ViewBuilder
    private func fieldSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.md) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsPrimary)
                Text(title)
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
            }
            content()
        }
    }

    private var priorityColor: Color {
        switch info.priorityLevel {
        case .critical: return .dsStatusActive
        case .high:     return .dsStatusTreat
        case .moderate: return Color(hex: "4A90A4")
        }
    }
}

// MARK: - Control Method Row

private struct ControlMethodRow: View {
    let method: TreatmentMethod

    var body: some View {
        HStack(alignment: .top, spacing: DSSpace.md) {
            Image(systemName: method.systemIconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.dsPrimary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(method.displayName)
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsInk)
                Text(method.instructions)
                    .font(DSFont.caption)
                    .foregroundStyle(Color.dsInk2)
            }
            Spacer()
        }
        .padding(DSSpace.md)
        .background(Color.dsPrimarySoft)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
    }
}
