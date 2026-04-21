import SwiftUI

// MARK: - ActivityView
// Consolidates Sightings, Patrols, and Tasks into a single segmented tab.

struct ActivityView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @State private var selectedSegment = 0

    private let segments = ["Sightings", "Patrols", "Tasks"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment picker
                Picker("Activity", selection: $selectedSegment) {
                    ForEach(segments.indices, id: \.self) { i in
                        Text(segments[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DSSpace.lg)
                .padding(.vertical, DSSpace.sm)
                .background(Color.dsBackground)

                Divider()
                    .overlay(Color.dsDivider)

                // Content
                Group {
                    switch selectedSegment {
                    case 0: SightingListView()
                    case 1: PatrolView()
                    case 2: TaskListView()
                    default: EmptyView()
                    }
                }
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
