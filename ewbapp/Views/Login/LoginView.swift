import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @StateObject private var viewModel: LoginViewModel

    init() {
        // Will be properly initialised in .onAppear via environmentObject
        _viewModel = StateObject(wrappedValue: LoginViewModel(
            authManager: AppEnvironment.shared.authManager,
            persistence: AppEnvironment.shared.persistence
        ))
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            // Logo / title
            VStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("Lama Lama Rangers")
                    .font(.title.bold())
                Text("Lantana Control")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()

            // Ranger picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Ranger")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.rangers, id: \.id) { ranger in
                            RangerChip(
                                ranger: ranger,
                                isSelected: viewModel.selectedRanger?.id == ranger.id
                            ) {
                                viewModel.selectRanger(ranger)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding(.horizontal)

            // PIN entry
            if viewModel.selectedRanger != nil {
                VStack(spacing: 12) {
                    Text("Enter PIN")
                        .font(.headline)
                    PINEntryView(
                        enteredPIN: $viewModel.enteredPIN,
                        onDigit: { viewModel.appendPINDigit($0) },
                        onDelete: { viewModel.deletePINDigit() }
                    )
                }
            }

            if let error = viewModel.loginError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
            }

            Spacer()
        }
        .onAppear {
            viewModel.seedDemoRangersIfNeeded(authManager: appEnv.authManager, persistence: appEnv.persistence)
        }
    }
}

struct RangerChip: View {
    let ranger: RangerProfile
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(ranger.displayName ?? "Ranger")
                .font(.callout.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.green : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
