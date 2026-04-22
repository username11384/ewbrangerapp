import SwiftUI

struct SafetyCheckInView: View {
    @EnvironmentObject private var vm: SafetyCheckInViewModel

    private let intervalOptions = [30, 60, 90, 120]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DSSpace.xl) {
                    // MARK: Countdown Ring
                    countdownRing

                    // MARK: Interval Selector (inactive only)
                    if !vm.isActive {
                        intervalPicker
                    }

                    // MARK: Action Buttons
                    actionButtons
                }
                .padding(.horizontal, DSSpace.lg)
                .padding(.top, DSSpace.xl)
                .padding(.bottom, DSSpace.xxxl)
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle("Safety Check-In")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Subviews

    private var countdownRing: some View {
        VStack(spacing: DSSpace.lg) {
            ZStack {
                // Track
                Circle()
                    .stroke(Color.dsStatusClearedSoft, lineWidth: 12)
                    .frame(width: 200, height: 200)

                // Progress arc
                Circle()
                    .trim(from: 0, to: vm.isActive ? vm.progress : 1)
                    .stroke(
                        vm.isActive && vm.progress < 0.25 ? Color.dsStatusActive : Color.dsStatusCleared,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: vm.progress)

                // Inner content
                VStack(spacing: DSSpace.xs) {
                    if vm.isActive {
                        Text(vm.timeFormatted)
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.dsInk)
                            .contentTransition(.numericText())
                            .animation(.default, value: vm.timeFormatted)
                        Text("remaining")
                            .font(DSFont.callout)
                            .foregroundStyle(Color.dsInk3)
                    } else {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(Color.dsStatusCleared)
                        Text("Ready")
                            .font(DSFont.subhead)
                            .foregroundStyle(Color.dsInk3)
                    }
                }
            }

            // Status label
            statusLabel
        }
        .padding(.top, DSSpace.md)
    }

    private var statusLabel: some View {
        Group {
            if vm.isActive {
                if vm.progress < 0.25 {
                    Label("Check-in soon", systemImage: "exclamationmark.triangle.fill")
                        .font(DSFont.callout)
                        .foregroundStyle(Color.dsStatusActive)
                } else {
                    Label("Timer running", systemImage: "checkmark.shield.fill")
                        .font(DSFont.callout)
                        .foregroundStyle(Color.dsStatusCleared)
                }
            } else {
                Text("Set an interval and start your shift timer")
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsInk3)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var intervalPicker: some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            Text("Check-In Interval")
                .font(DSFont.subhead)
                .foregroundStyle(Color.dsInk2)

            Picker("Interval", selection: $vm.intervalMinutes) {
                ForEach(intervalOptions, id: \.self) { minutes in
                    Text("\(minutes) min").tag(minutes)
                }
            }
            .pickerStyle(.segmented)
        }
        .dsCard()
    }

    private var actionButtons: some View {
        VStack(spacing: DSSpace.md) {
            // Check-in button — visible when active
            if vm.isActive {
                DSPrimaryButton(
                    title: "I'm Safe — Check In",
                    icon: "checkmark.shield.fill",
                    isLoading: false
                ) {
                    withAnimation { vm.checkIn() }
                }
            }

            // Start / Stop toggle
            if vm.isActive {
                Button {
                    withAnimation { vm.stopTimer() }
                } label: {
                    HStack(spacing: DSSpace.sm) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Stop Timer")
                            .font(DSFont.subhead)
                    }
                    .foregroundStyle(Color.dsStatusActive)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.dsStatusActiveSoft)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                            .strokeBorder(Color.dsStatusActive.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    withAnimation { vm.startTimer() }
                } label: {
                    HStack(spacing: DSSpace.sm) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Start Timer")
                            .font(DSFont.subhead)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.dsPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
                    .shadow(color: Color.dsPrimary.opacity(0.25), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    SafetyCheckInView()
        .environmentObject(SafetyCheckInViewModel())
}
