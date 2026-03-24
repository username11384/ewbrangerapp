import SwiftUI

struct PatrolView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: PatrolViewModel

    init() {
        _viewModel = StateObject(wrappedValue: PatrolViewModel(
            persistence: AppEnvironment.shared.persistence,
            rangerID: AppEnvironment.shared.authManager.currentRangerID ?? UUID()
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let _ = viewModel.activePatrol {
                    ActivePatrolView(viewModel: viewModel)
                } else {
                    VStack(spacing: 24) {
                        // Start patrol
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Start New Patrol")
                                .font(.headline)
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
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding()

                        // Past patrols
                        PatrolListView(patrols: viewModel.patrols)
                    }
                }
            }
            .navigationTitle("Patrol")
            .onAppear { viewModel.load() }
        }
    }
}
