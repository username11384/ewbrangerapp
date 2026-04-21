import SwiftUI

struct LogSightingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: LogSightingViewModel

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
