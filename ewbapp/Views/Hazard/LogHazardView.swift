import SwiftUI

struct LogHazardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: HazardViewModel

    init() {
        _viewModel = StateObject(wrappedValue: HazardViewModel(
            persistence: AppEnvironment.shared.persistence,
            locationManager: AppEnvironment.shared.locationManager
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpace.xl) {

                    // MARK: GPS Location
                    GPSCaptureView(
                        location: viewModel.capturedLocation,
                        accuracyLevel: viewModel.accuracyLevel,
                        onRecapture: { viewModel.recaptureLocation() }
                    )

                    // MARK: Hazard Type
                    VStack(alignment: .leading, spacing: DSSpace.sm) {
                        Text("Hazard Type")
                            .font(DSFont.headline)
                            .foregroundStyle(Color.dsInk)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpace.sm) {
                            ForEach(HazardViewModel.HazardType.allCases, id: \.self) { type in
                                HazardTypeChip(
                                    type: type,
                                    isSelected: viewModel.selectedType == type
                                ) {
                                    viewModel.selectedType = type
                                }
                            }
                        }
                    }

                    // MARK: Severity
                    VStack(alignment: .leading, spacing: DSSpace.sm) {
                        Text("Severity")
                            .font(DSFont.headline)
                            .foregroundStyle(Color.dsInk)

                        HStack(spacing: DSSpace.sm) {
                            ForEach(HazardViewModel.HazardSeverity.allCases, id: \.self) { sev in
                                SeverityChip(
                                    severity: sev,
                                    isSelected: viewModel.selectedSeverity == sev
                                ) {
                                    viewModel.selectedSeverity = sev
                                }
                            }
                        }
                    }

                    // MARK: Title
                    VStack(alignment: .leading, spacing: DSSpace.sm) {
                        Text("Title")
                            .font(DSFont.headline)
                            .foregroundStyle(Color.dsInk)
                        TextField("Brief description of hazard", text: $viewModel.title)
                            .font(DSFont.body)
                            .padding(DSSpace.md)
                            .background(Color.dsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                    .strokeBorder(Color.dsDivider, lineWidth: 0.75)
                            )
                    }

                    // MARK: Notes
                    VStack(alignment: .leading, spacing: DSSpace.sm) {
                        Text("Notes (optional)")
                            .font(DSFont.headline)
                            .foregroundStyle(Color.dsInk)
                        TextEditor(text: $viewModel.notes)
                            .font(DSFont.body)
                            .frame(height: 90)
                            .padding(DSSpace.md)
                            .background(Color.dsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                    .strokeBorder(Color.dsDivider, lineWidth: 0.75)
                            )
                    }

                    // MARK: Photo
                    PhotoCaptureView(photoFilenames: Binding(
                        get: { viewModel.photoPath.map { [$0] } ?? [] },
                        set: { viewModel.photoPath = $0.first }
                    ))

                    // MARK: Error
                    if let error = viewModel.saveError {
                        Text(error)
                            .font(DSFont.callout)
                            .foregroundStyle(Color.dsStatusActive)
                    }

                    // MARK: Save Button
                    LargeButton(
                        title: "Log Hazard",
                        action: {
                            Task {
                                await viewModel.logHazard()
                                if viewModel.didSave { dismiss() }
                            }
                        },
                        isEnabled: viewModel.canSave,
                        isLoading: viewModel.isSaving
                    )
                    .padding(.bottom, DSSpace.lg)
                }
                .padding(.horizontal, DSSpace.lg)
                .padding(.top, DSSpace.lg)
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle("Log Hazard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dsInk2)
                }
            }
        }
    }
}

// MARK: - Hazard Type Chip

private struct HazardTypeChip: View {
    let type: HazardViewModel.HazardType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DSSpace.xs) {
                Image(systemName: type.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Color.dsInk2)
                Text(type.rawValue)
                    .font(DSFont.caption)
                    .foregroundStyle(isSelected ? .white : Color.dsInk2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .padding(.horizontal, DSSpace.xs)
            .background(isSelected ? Color.dsPrimary : Color.dsSurface)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                    .strokeBorder(isSelected ? Color.dsPrimary : Color.dsDivider, lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Severity Chip

private struct SeverityChip: View {
    let severity: HazardViewModel.HazardSeverity
    let isSelected: Bool
    let action: () -> Void

    private var activeColor: Color {
        switch severity {
        case .low:    return .dsStatusCleared
        case .medium: return .dsStatusTreat
        case .high:   return .dsStatusActive
        }
    }

    var body: some View {
        Button(action: action) {
            Text(severity.rawValue)
                .font(DSFont.callout)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .foregroundStyle(isSelected ? .white : Color.dsInk2)
                .background(isSelected ? activeColor : Color.dsSurface)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.xs, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.xs, style: .continuous)
                        .strokeBorder(isSelected ? activeColor : Color.dsDivider, lineWidth: 0.75)
                )
        }
        .buttonStyle(.plain)
    }
}
