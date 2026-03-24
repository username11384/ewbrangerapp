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
                VStack(spacing: 20) {
                    GPSCaptureView(
                        location: viewModel.capturedLocation,
                        accuracyLevel: viewModel.accuracyLevel,
                        onRecapture: { viewModel.recaptureLocation() }
                    )
                    VariantPickerView(selectedVariant: $viewModel.selectedVariant)
                    SizePickerView(selectedSize: $viewModel.selectedSize)
                    PhotoCaptureView(photoFilenames: $viewModel.photoFilenames)
                    if let rec = viewModel.controlRecommendation {
                        ControlRecommendationView(recommendation: rec)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.headline)
                        TextEditor(text: $viewModel.notes)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    if let error = viewModel.saveError {
                        Text(error).foregroundColor(.red).font(.callout)
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
                        isLoading: viewModel.isSaving,
                        color: .green
                    )
                    .padding(.bottom, 8)
                }
                .padding()
            }
            .navigationTitle("New Sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
