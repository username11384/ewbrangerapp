import SwiftUI

struct LogSightingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: LogSightingViewModel

    /// Tracks which species the dismissed alert was shown for.
    /// Resets when the species changes so the banner re-appears.
    @State private var dismissedAlertForSpecies: InvasiveSpecies? = nil

    private var currentPhenologyAlert: PhenologyAlert? {
        let month = Calendar.current.component(.month, from: Date())
        return PhenologyAlertStore.alert(for: viewModel.selectedSpecies, month: month)
    }

    init(rangerID: UUID) {
        _viewModel = StateObject(wrappedValue: LogSightingViewModel(
            locationManager: AppEnvironment.shared.locationManager,
            persistence: AppEnvironment.shared.persistence,
            rangerID: rangerID
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpace.xl) {
                    GPSCaptureView(
                        location: viewModel.capturedLocation,
                        accuracyLevel: viewModel.accuracyLevel,
                        onRecapture: { viewModel.recaptureLocation() }
                    )

                    SpeciesPickerView(selectedSpecies: $viewModel.selectedSpecies)
                        .onChange(of: viewModel.selectedSpecies) { _ in
                            // Re-show alert whenever the species changes
                            dismissedAlertForSpecies = nil
                        }

                    if let alert = currentPhenologyAlert,
                       dismissedAlertForSpecies != viewModel.selectedSpecies {
                        PhenologyAlertBanner(alert: alert) {
                            dismissedAlertForSpecies = viewModel.selectedSpecies
                        }
                    }

                    if viewModel.selectedSpecies == .lantana {
                        BiocontrolPromptCard(observation: $viewModel.biocontrolObservation)
                    }

                    SizePickerView(selectedSize: $viewModel.selectedSize)

                    PhotoCaptureView(photoFilenames: $viewModel.photoFilenames)

                    if let rec = viewModel.controlRecommendation {
                        ControlRecommendationView(recommendation: rec)
                    }

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

                    if let error = viewModel.saveError {
                        Text(error)
                            .font(DSFont.callout)
                            .foregroundStyle(Color.dsStatusActive)
                    }

                    LargeButton(
                        title: "Save Sighting",
                        action: {
                            Task {
                                await viewModel.save()
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
            .navigationTitle("Log Sighting")
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

// MARK: - Phenology Alert Banner

struct PhenologyAlertBanner: View {
    let alert: PhenologyAlert
    let onDismiss: () -> Void

    private var urgencyColor: Color {
        switch alert.urgencyLevel {
        case .urgent:   return Color(hex: "C94040")  // dsStatusActive red
        case .priority: return Color(hex: "C4692A")  // dsAccent orange
        case .routine:  return Color(hex: "2A7A4A")  // dsStatusCleared green
        }
    }

    private var urgencySoftColor: Color {
        switch alert.urgencyLevel {
        case .urgent:   return Color(hex: "FAE8E8")
        case .priority: return Color(hex: "F2DEC8")
        case .routine:  return Color(hex: "DAEEE3")
        }
    }

    private var urgencyIcon: String {
        switch alert.urgencyLevel {
        case .urgent:   return "exclamationmark.triangle.fill"
        case .priority: return "calendar.badge.exclamationmark"
        case .routine:  return "leaf.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            HStack(alignment: .top, spacing: DSSpace.sm) {
                Image(systemName: urgencyIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(urgencyColor)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: DSSpace.xs) {
                        Text(alert.phase)
                            .font(DSFont.headline)
                            .foregroundStyle(Color.dsInk)
                        Spacer()
                        Text(alert.urgencyLevel.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(urgencyColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(urgencyColor.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text(alert.actionRecommended)
                        .font(DSFont.callout)
                        .foregroundStyle(Color.dsInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.dsInk3)
                        .padding(6)
                        .background(Color.dsDivider.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DSSpace.md)
        .background(urgencySoftColor)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .strokeBorder(urgencyColor.opacity(0.5), lineWidth: 0.75)
        )
    }
}

// MARK: - Lantana Biocontrol Prompt Card

struct BiocontrolPromptCard: View {
    @Binding var observation: LogSightingViewModel.BiocontrolObservation

    var body: some View {
        VStack(spacing: DSSpace.md) {
            HStack(spacing: DSSpace.sm) {
                Image(systemName: "ant.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "856404"))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lantana Bug Check")
                        .font(DSFont.headline)
                        .foregroundStyle(Color.dsInk)
                    Text("Is Aconophora compressa (Lantana bug) present?")
                        .font(DSFont.callout)
                        .foregroundStyle(Color.dsInk3)
                }
                Spacer()
            }

            HStack(spacing: DSSpace.sm) {
                ForEach([
                    (LogSightingViewModel.BiocontrolObservation.observed, "Observed"),
                    (.notObserved, "Not Seen"),
                    (.unsure, "Unsure")
                ], id: \.0) { value, label in
                    Button {
                        observation = value
                    } label: {
                        Text(label)
                            .font(DSFont.callout)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .foregroundStyle(observation == value ? .white : Color.dsInk2)
                            .background(observation == value ? Color.dsPrimary : Color.dsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.xs, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.xs, style: .continuous)
                                    .strokeBorder(Color.dsDivider, lineWidth: 0.75)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if observation == .observed {
                HStack(spacing: DSSpace.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.dsAccent)
                    Text("Biocontrol present — consider delaying foliar spray")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsAccent)
                    Spacer()
                }
                .padding(DSSpace.md)
                .background(Color.dsAccent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
            }
        }
        .padding(DSSpace.md)
        .background(Color(hex: "FFF3CD"))
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .strokeBorder(Color(hex: "856404"), lineWidth: 0.75)
        )
    }
}
