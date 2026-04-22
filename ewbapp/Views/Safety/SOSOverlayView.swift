import SwiftUI

// MARK: - SOSOverlayView

struct SOSOverlayView: View {
    enum Mode {
        case alarm
        case rescue(rangerName: String)
    }

    let mode: Mode
    let onDismiss: () -> Void

    @EnvironmentObject private var safetyVM: SafetyCheckInViewModel

    // Alarm-mode animation state
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0.8
    @State private var dotsPhase: Int = 0
    @State private var dotsTimer: Timer? = nil

    // Proximity ring animation (rescue near/found state)
    @State private var proximityPulse: CGFloat = 1.0
    @State private var proximityPulseOpacity: Double = 0.7

    var body: some View {
        ZStack {
            // Consistent dark-red gradient background for both modes
            overlayBackground

            // Alarm-mode broadcast rings sit behind content
            if case .alarm = mode {
                broadcastRings
            }

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                mainContent
                    .padding(.horizontal, DSSpace.xl)
                Spacer(minLength: 0)
                actionButtons
                    .padding(.horizontal, DSSpace.xl)
                    .padding(.bottom, 56)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startRingAnimation()
            startDotsAnimation()
        }
        .onDisappear {
            dotsTimer?.invalidate()
            dotsTimer = nil
        }
    }

    // MARK: - Background

    private var overlayBackground: some View {
        LinearGradient(
            colors: [Color(hex: "2C0606"), Color(hex: "7A1212")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Broadcast rings (alarm only)

    private var broadcastRings: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(Color.white.opacity(0.08 - Double(i) * 0.015), lineWidth: 1)
                    .scaleEffect(ringScale + CGFloat(i) * 0.3)
                    .opacity(ringOpacity - Double(i) * 0.18)
                    .frame(width: 340, height: 340)
                    .animation(
                        .easeOut(duration: 2.2)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.55),
                        value: ringScale
                    )
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch mode {
        case .alarm:
            alarmContent
        case .rescue(let rangerName):
            rescueContent(rangerName: rangerName)
        }
    }

    // MARK: - Alarm Content

    private var alarmContent: some View {
        VStack(spacing: DSSpace.xl) {
            // Status badge
            statusBadge(icon: "antenna.radiowaves.left.and.right", label: "SOS TRIGGERED")

            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 108, height: 108)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Labels
            VStack(spacing: DSSpace.sm) {
                Text("Check-In Missed")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(0.5)
                Text("Your safety timer has expired")
                    .font(DSFont.subhead)
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            // Beacon status pill
            HStack(spacing: DSSpace.sm) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 7, height: 7)
                    .opacity(ringOpacity)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: ringOpacity)
                Text("Broadcasting Bluetooth beacon\(dotsString)")
                    .font(DSFont.callout)
                    .foregroundStyle(Color.white.opacity(0.9))
                    .animation(nil, value: dotsString)
            }
            .padding(.horizontal, DSSpace.lg)
            .padding(.vertical, DSSpace.sm)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.75))
        }
    }

    // MARK: - Rescue Content

    private func rescueContent(rangerName: String) -> some View {
        VStack(spacing: DSSpace.xl) {
            // Status badge
            statusBadge(icon: "antenna.radiowaves.left.and.right.slash", label: "SOS BEACON RECEIVED")

            if safetyVM.sosIsResponding {
                respondingContent(rangerName: rangerName)
            } else {
                preRespondContent(rangerName: rangerName)
            }
        }
    }

    private func preRespondContent(rangerName: String) -> some View {
        VStack(spacing: DSSpace.xl) {
            // Ranger identity
            VStack(spacing: DSSpace.xs) {
                Text(rangerName)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("missed their safety check-in")
                    .font(DSFont.subhead)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // Compass — pre-respond state (wider wobble)
            compassView(size: 160)

            // Distance pill
            distancePill
        }
    }

    private func respondingContent(rangerName: String) -> some View {
        VStack(spacing: DSSpace.lg) {
            // Ranger label (compact)
            Text(rangerName)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            // Compass — tightens as distance shrinks
            compassView(size: 180)

            // Distance + GPS panel
            VStack(spacing: DSSpace.sm) {
                // Large distance readout
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(safetyVM.sosDistanceDisplay)
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.4), value: safetyVM.sosDistanceDisplay)
                    Text("away")
                        .font(DSFont.callout)
                        .foregroundStyle(Color.white.opacity(0.6))
                        .padding(.bottom, 4)
                }

                // GPS coordinate panel
                gpsPanel
            }
        }
    }

    // MARK: - Compass

    private func compassView(size: CGFloat) -> some View {
        let phase = safetyVM.sosProximityPhase
        let isFound = phase == 2
        let isNear = phase == 1

        return ZStack {
            // Outer ring
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                .frame(width: size, height: size)

            // Disc
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size - 4, height: size - 4)

            if !isFound {
                // Cardinal labels
                compassCardinals(size: size)
            }

            if isFound {
                // Found state — checkmark + green proximity pulse
                ZStack {
                    Circle()
                        .stroke(Color(hex: "34C759").opacity(0.4), lineWidth: 2)
                        .frame(width: size * 0.55, height: size * 0.55)
                        .scaleEffect(proximityPulse)
                        .opacity(proximityPulseOpacity)
                        .animation(
                            .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                            value: proximityPulse
                        )

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: size * 0.28, weight: .bold))
                        .foregroundStyle(Color(hex: "34C759"))
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                        proximityPulse = 1.5
                        proximityPulseOpacity = 0
                    }
                }
            } else if isNear {
                // Near state — person icon with tight arc
                ZStack {
                    // Proximity arc behind person
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                        .frame(width: size * 0.5, height: size * 0.5)
                        .scaleEffect(proximityPulse)
                        .opacity(proximityPulseOpacity)
                        .animation(
                            .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                            value: proximityPulse
                        )
                        .onAppear {
                            withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                                proximityPulse = 1.35
                                proximityPulseOpacity = 0
                            }
                        }

                    // Person icon rotates to locked bearing
                    Image(systemName: "figure.stand")
                        .font(.system(size: size * 0.22, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(safetyVM.sosBearing))
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.75),
                            value: safetyVM.sosBearing
                        )
                }
            } else {
                // Searching / tracking — directional arrow
                Image(systemName: "location.north.fill")
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(safetyVM.sosBearing))
                    .animation(
                        .interpolatingSpring(stiffness: 120, damping: 18),
                        value: safetyVM.sosBearing
                    )
            }
        }
    }

    private func compassCardinals(size: CGFloat) -> some View {
        let inset = size * 0.14
        return ZStack {
            VStack {
                Text("N").font(DSFont.caption).foregroundStyle(Color.white.opacity(0.4))
                    .padding(.top, inset)
                Spacer()
                Text("S").font(DSFont.caption).foregroundStyle(Color.white.opacity(0.4))
                    .padding(.bottom, inset)
            }
            .frame(height: size * 0.8)
            HStack {
                Text("W").font(DSFont.caption).foregroundStyle(Color.white.opacity(0.4))
                    .padding(.leading, inset)
                Spacer()
                Text("E").font(DSFont.caption).foregroundStyle(Color.white.opacity(0.4))
                    .padding(.trailing, inset)
            }
            .frame(width: size * 0.8)
        }
    }

    // MARK: - GPS Panel

    private var gpsPanel: some View {
        let (latStr, lonStr) = safetyVM.sosGPSStrings
        return VStack(spacing: 6) {
            gpsRow(label: "LAT", value: latStr)
            gpsRow(label: "LON", value: lonStr)
        }
        .padding(.horizontal, DSSpace.md)
        .padding(.vertical, DSSpace.sm)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75)
        )
    }

    private func gpsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.45))
                .frame(width: 28, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.5), value: value)
            Spacer()
            // Accuracy dot — green when close, amber when far
            Circle()
                .fill(safetyVM.sosDistanceMeters < 20 ? Color(hex: "34C759") : Color(hex: "FFB340"))
                .frame(width: 6, height: 6)
        }
    }

    // MARK: - Distance Pill

    private var distancePill: some View {
        HStack(spacing: DSSpace.sm) {
            Image(systemName: "dot.radiowaves.up.forward")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
            Text(safetyVM.sosDistanceDisplay)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.4), value: safetyVM.sosDistanceDisplay)
            Text("estimated")
                .font(DSFont.caption)
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .padding(.horizontal, DSSpace.md)
        .padding(.vertical, DSSpace.sm)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75))
    }

    // MARK: - Status Badge

    private func statusBadge(icon: String, label: String) -> some View {
        HStack(spacing: DSSpace.sm) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .tracking(1.5)
        }
        .padding(.horizontal, DSSpace.md)
        .padding(.vertical, DSSpace.xs)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.75))
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch mode {
        case .alarm:
            primaryButton(
                icon: "checkmark.shield.fill",
                label: "Cancel SOS — I'm Safe",
                action: onDismiss
            )

        case .rescue:
            VStack(spacing: DSSpace.md) {
                if safetyVM.sosIsResponding {
                    primaryButton(
                        icon: "checkmark.circle.fill",
                        label: safetyVM.sosProximityPhase == 2 ? "Mark as Found" : "Mark as Found",
                        action: onDismiss
                    )
                } else {
                    primaryButton(
                        icon: "figure.walk",
                        label: "I'm Responding",
                        action: { withAnimation(.easeInOut(duration: 0.4)) { safetyVM.startResponding() } }
                    )
                    Button { onDismiss() } label: {
                        Text("Dismiss")
                            .font(DSFont.callout)
                            .foregroundStyle(Color.white.opacity(0.5))
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func primaryButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DSSpace.sm) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(label)
                    .font(DSFont.subhead)
            }
            .foregroundStyle(Color(hex: "7A1212"))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var dotsString: String {
        String(repeating: ".", count: (dotsPhase % 3) + 1)
    }

    private func startRingAnimation() {
        withAnimation(.easeOut(duration: 2.2).repeatForever(autoreverses: false)) {
            ringScale = 1.5
            ringOpacity = 0.0
        }
    }

    private func startDotsAnimation() {
        dotsTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            Task { @MainActor in self.dotsPhase += 1 }
        }
    }
}
