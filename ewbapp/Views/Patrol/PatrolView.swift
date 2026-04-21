import SwiftUI

struct PatrolView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: PatrolViewModel
    @State private var historyTab = 0 // 0 = List, 1 = Calendar

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
                        VStack(spacing: 24) {
                            // Start patrol
                            VStack(alignment: .leading, spacing: DSSpace.md) {
                                Text("Start New Patrol")
                                    .font(DSFont.headline)
                                    .foregroundStyle(Color.dsInk)
                                Picker("Area", selection: $viewModel.selectedAreaName) {
                                    ForEach(PortStewartZones.patrolAreas, id: \.self) { area in
                                        Text(area).tag(area)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 120)
                                LargeButton(title: "Start Patrol", action: {
                                    Task { await viewModel.startPatrol() }
                                })
                            }
                            .dsCard()
                            .padding(.horizontal)

                            // History toggle
                            Picker("View", selection: $historyTab) {
                                Text("List").tag(0)
                                Text("Calendar").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            if historyTab == 0 {
                                PatrolListView(patrols: viewModel.patrols)
                                    .frame(minHeight: 200)
                            } else {
                                PatrolCalendarView(patrols: viewModel.patrols)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Patrol")
            .onAppear { viewModel.load() }
        }
    }
}
