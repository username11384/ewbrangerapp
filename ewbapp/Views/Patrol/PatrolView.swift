import SwiftUI

struct PatrolView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: PatrolViewModel
    @State private var historyTab = 0

    init() {
        let rangerID = AppEnvironment.shared.authManager.currentRangerID ?? {
            assertionFailure("PatrolView accessed without authenticated ranger")
            return UUID()
        }()
        _viewModel = StateObject(wrappedValue: PatrolViewModel(
            persistence: AppEnvironment.shared.persistence,
            rangerID: rangerID
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let _ = viewModel.activePatrol {
                    ActivePatrolView(viewModel: viewModel)
                } else {
                    ScrollView {
                        VStack(spacing: DSSpace.lg) {
                            startPatrolCard
                            historySection
                        }
                        .padding(.vertical, DSSpace.md)
                    }
                    .background(Color.dsBackground.ignoresSafeArea())
                }
            }
            .navigationTitle("Patrol")
            .onAppear { viewModel.load() }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AreaChecklistView(
                        areaName: viewModel.activePatrol?.areaName ?? viewModel.selectedAreaName
                    )) {
                        Label("Checklist", systemImage: "checklist")
                    }
                }
            }
        }
    }

    // MARK: - Start Patrol Card

    private var startPatrolCard: some View {
        VStack(alignment: .leading, spacing: DSSpace.md) {
            HStack(spacing: 6) {
                Image(systemName: "figure.walk.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsPrimary)
                Text("Start New Patrol")
                    .font(DSFont.headline)
                    .foregroundStyle(Color.dsInk)
            }

            // Area picker — menu style
            Menu {
                ForEach(PortStewartZones.patrolAreas, id: \.self) { area in
                    Button(area) { viewModel.selectedAreaName = area }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Area")
                            .font(DSFont.caption)
                            .foregroundStyle(Color.dsInk3)
                        Text(viewModel.selectedAreaName)
                            .font(DSFont.subhead)
                            .foregroundStyle(Color.dsInk)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.dsInk3)
                }
                .padding(DSSpace.md)
                .background(Color.dsSurface)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .strokeBorder(Color.dsDivider, lineWidth: 0.75)
                )
            }

            LargeButton(title: "Start Patrol") {
                Task { await viewModel.startPatrol() }
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpace.lg)
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(spacing: DSSpace.md) {
            // Segment toggle
            Picker("View", selection: $historyTab) {
                Text("List").tag(0)
                Text("Calendar").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DSSpace.lg)

            if historyTab == 0 {
                PatrolListView(patrols: viewModel.patrols)
            } else {
                PatrolCalendarView(patrols: viewModel.patrols)
                    .dsCard()
                    .padding(.horizontal, DSSpace.lg)
            }
        }
    }
}
