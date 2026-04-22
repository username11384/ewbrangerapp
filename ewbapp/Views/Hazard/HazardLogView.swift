import SwiftUI

struct HazardLogView: View {
    @StateObject private var viewModel: HazardViewModel
    @State private var showLogSheet = false

    init() {
        _viewModel = StateObject(wrappedValue: HazardViewModel(
            persistence: AppEnvironment.shared.persistence,
            locationManager: AppEnvironment.shared.locationManager
        ))
    }

    var body: some View {
        Group {
            if viewModel.hazards.isEmpty {
                DSEmptyState(
                    icon: "exclamationmark.triangle",
                    title: "No hazards logged",
                    message: "Tap + to log a hazard or incident."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.hazards, id: \.id) { hazard in
                        HazardCard(hazard: hazard)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.dsBackground)
                    }
                    .onDelete { offsets in
                        offsets.map { viewModel.hazards[$0] }.forEach { viewModel.delete($0) }
                    }
                }
                .listStyle(.plain)
                .background(Color.dsBackground)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationTitle("Hazards")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showLogSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dsPrimary)
                }
            }
        }
        .sheet(isPresented: $showLogSheet, onDismiss: { viewModel.load() }) {
            LogHazardView()
        }
        .onAppear {
            viewModel.load()
        }
    }
}

// MARK: - Hazard Card

private struct HazardCard: View {
    let hazard: HazardLog
    @State private var appeared = false

    private var hazardType: HazardViewModel.HazardType {
        HazardViewModel.HazardType(rawValue: hazard.hazardType ?? "Other") ?? .other
    }

    private var severity: HazardViewModel.HazardSeverity {
        HazardViewModel.HazardSeverity(rawValue: hazard.severity ?? "Low") ?? .low
    }

    private var severityColor: Color {
        switch severity {
        case .low:    return .dsStatusCleared
        case .medium: return .dsStatusTreat
        case .high:   return .dsStatusActive
        }
    }

    private var severitySoftColor: Color {
        switch severity {
        case .low:    return .dsStatusClearedSoft
        case .medium: return .dsStatusTreatSoft
        case .high:   return .dsStatusActiveSoft
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Severity accent bar
            Rectangle()
                .fill(severityColor)
                .frame(width: 4)

            HStack(alignment: .center, spacing: DSSpace.md) {
                // Type icon
                ZStack {
                    Circle()
                        .fill(severityColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: hazardType.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(severityColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(hazard.title ?? "Untitled")
                        .font(DSFont.subhead)
                        .foregroundStyle(Color.dsInk)
                    HStack(spacing: 6) {
                        Text(hazardType.rawValue)
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                        if let ts = hazard.timestamp {
                            Text("·")
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                            Text(ts, style: .relative)
                                .font(DSFont.caption)
                                .foregroundStyle(Color.dsInk3)
                        }
                    }
                }

                Spacer()

                // Severity badge
                DSStatusBadge(
                    label: severity.rawValue,
                    color: severityColor,
                    softColor: severitySoftColor
                )
            }
            .padding(.horizontal, DSSpace.md)
            .padding(.vertical, DSSpace.md)
        }
        .background(Color.dsCard)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .strokeBorder(Color.dsDivider.opacity(0.6), lineWidth: 0.75)
        )
        .shadow(color: Color.dsInk.opacity(0.04), radius: 3, x: 0, y: 1)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
