import SwiftUI
import CoreLocation

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
        VStack(spacing: 0) {
            grabber
            header
            ScrollView {
                VStack(spacing: 18) {
                    gpsBadge
                    variantSection
                    sizeSection
                    photosSection
                    notesSection
                    if let error = viewModel.saveError {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.statusActive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    submitSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.bottom, 24)
            }
        }
        .background(Color.paper.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.paper)
    }

    // MARK: - Header

    private var grabber: some View {
        Capsule()
            .fill(Color.lineBase.opacity(0.22))
            .frame(width: 40, height: 4)
            .padding(.top, 8)
            .padding(.bottom, 6)
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 15))
                .foregroundColor(.euc)
            Spacer()
            Text("Log sighting")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.ink)
            Spacer()
            Color.clear.frame(width: 48, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - GPS

    private var gpsBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "scope")
                .font(.system(size: 20))
                .foregroundColor(.euc)
            VStack(alignment: .leading, spacing: 2) {
                Text(coordinateString)
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(.ink)
                Text(accuracySubtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.ink3)
            }
            Spacer(minLength: 0)
            Text(accuracyBadge.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(accuracyBadge.fg)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(accuracyBadge.bg)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.eucSoft))
    }

    private var coordinateString: String {
        if let loc = viewModel.capturedLocation {
            return String(format: "%.5f°, %.5f°", loc.coordinate.latitude, loc.coordinate.longitude)
        }
        return "Capturing GPS…"
    }

    private var accuracySubtitle: String {
        if let loc = viewModel.capturedLocation {
            return String(format: "GPS captured · accuracy ±%.0f m", loc.horizontalAccuracy)
        }
        return "Waiting for fix…"
    }

    private var accuracyBadge: (label: String, fg: Color, bg: Color) {
        switch viewModel.accuracyLevel {
        case .good:    return ("GOOD",   .statusCleared, .statusClearedSoft)
        case .fair:    return ("FAIR",   .statusTreat,   .statusTreatSoft)
        case .poor:    return ("POOR",   .statusActive,  .statusActiveSoft)
        case .unknown: return ("—",      .ink3,          .paperDeep)
        }
    }

    // MARK: - Variant

    private var variantSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Variant")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.ink)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(LantanaVariant.allCases, id: \.self) { variant in
                    variantCell(variant)
                }
            }
        }
    }

    private func variantCell(_ variant: LantanaVariant) -> some View {
        let selected = viewModel.selectedVariant == variant
        return Button {
            viewModel.selectedVariant = variant
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(variant.color)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 22, height: 22)
                    }
                }
                Text(variant.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(selected ? .white : .ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? variant.color : Color.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.clear : Color.lineBase.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Size

    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Infestation size")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.ink)
            HStack(spacing: 8) {
                sizeSegment(.small,  title: "Small",  sub: "<1m²")
                sizeSegment(.medium, title: "Medium", sub: "1–10m²")
                sizeSegment(.large,  title: "Large",  sub: ">10m²")
            }
        }
    }

    private func sizeSegment(_ size: InfestationSize, title: String, sub: String) -> some View {
        let selected = viewModel.selectedSize == size
        return Button {
            viewModel.selectedSize = size
        } label: {
            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selected ? .white : .ink)
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundColor(selected ? .white.opacity(0.85) : .ink3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? Color.euc : Color.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.clear : Color.lineBase.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photos

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Photos · \(viewModel.photoFilenames.count)/3")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.ink)
            HStack(spacing: 8) {
                ForEach(Array(viewModel.photoFilenames.prefix(3).enumerated()), id: \.offset) { _, _ in
                    photoTile
                }
                if viewModel.photoFilenames.count < 3 {
                    addPhotoTile
                }
            }
        }
    }

    private var photoTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.paperDeep)
            Image(systemName: "photo.fill")
                .font(.system(size: 22))
                .foregroundColor(.ink3)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 86)
    }

    private var addPhotoTile: some View {
        Button {
            Task { await viewModel.capturePhoto() }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "camera")
                    .font(.system(size: 20))
                    .foregroundColor(.ink3)
                Text("Take photo")
                    .font(.system(size: 11))
                    .foregroundColor(.ink3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        Color.lineBase.opacity(0.22),
                        style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.ink)
            TextEditor(text: $viewModel.notes)
                .font(.system(size: 14))
                .foregroundColor(.ink)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 76)
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(Color.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.lineBase.opacity(0.12), lineWidth: 1)
                )
        }
    }

    // MARK: - Submit

    private var submitSection: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    await viewModel.save()
                    if viewModel.didSave { dismiss() }
                }
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
                    }
                    Text(viewModel.isSaving ? "Saving…" : "Submit sighting")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(submitEnabled ? Color.ochre : Color.ochre.opacity(0.35))
                )
            }
            .buttonStyle(.plain)
            .disabled(!submitEnabled || viewModel.isSaving)

            HStack(spacing: 6) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 11))
                Text("Saved locally, will sync later")
                    .font(.system(size: 11))
            }
            .foregroundColor(.ink3)
        }
        .padding(.top, 4)
    }

    private var submitEnabled: Bool {
        viewModel.selectedVariant != nil && viewModel.canSave
    }
}
