import AudioToolbox
import Foundation
import UserNotifications
import Combine

@MainActor
final class SafetyCheckInViewModel: ObservableObject {
    @Published var isActive = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var intervalMinutes: Int = 60

    // SOS — alarm side (my timer expired)
    @Published var isSOSTriggered = false

    // SOS — rescue side (received another ranger's beacon)
    @Published var receivedSOSFrom: String? = nil
    @Published var sosIsResponding = false
    @Published var sosDistanceMeters: Double = 120.0
    @Published var sosBearing: Double = 42.0
    @Published var sosGPSLat: Double = -14.7031
    @Published var sosGPSLon: Double = 143.7089

    // MARK: - Computed — SOS display

    var sosDistanceDisplay: String {
        let m = sosDistanceMeters
        if m <= 0 { return "0m" }
        if m < 10 { return String(format: "%.1fm", m) }
        return String(format: "%.0fm", m)
    }

    /// Returns (latitude DMS string, longitude DMS string)
    var sosGPSStrings: (String, String) {
        (formatDMS(sosGPSLat, isLat: true), formatDMS(sosGPSLon, isLat: false))
    }

    /// 0 = searching, 1 = near, 2 = found
    var sosProximityPhase: Int {
        if sosDistanceMeters <= 5 { return 2 }
        if sosDistanceMeters <= 20 { return 1 }
        return 0
    }

    // MARK: - Private timers

    private var timer: Timer?
    private var alarmTimer: Timer?
    private var bearingTimer: Timer?
    private var approachTimer: Timer?
    private var totalTime: TimeInterval { TimeInterval(intervalMinutes * 60) }

    // MARK: - Computed — check-in

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return timeRemaining / totalTime
    }

    var timeFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Check-in actions

    func startTimer() {
        isActive = true
        timeRemaining = totalTime
        scheduleNotification()
        fireTimer()
    }

    func checkIn() {
        guard isActive else { return }
        cancelNotifications()
        timeRemaining = totalTime
        scheduleNotification()
    }

    func stopTimer() {
        isActive = false
        timeRemaining = 0
        timer?.invalidate()
        timer = nil
        cancelNotifications()
    }

    // MARK: - SOS alarm

    func triggerSOS() {
        isActive = false
        timer?.invalidate()
        timer = nil
        isSOSTriggered = true
        startAlarm()
    }

    func dismissSOS() {
        isSOSTriggered = false
        stopAlarm()
        cancelNotifications()
    }

    // MARK: - SOS rescue

    func startResponding() {
        sosIsResponding = true
        startApproachAnimation()
    }

    func dismissReceivedSOS() {
        receivedSOSFrom = nil
        sosIsResponding = false
        sosDistanceMeters = 120
        sosBearing = 42
        stopBearingAnimation()
        stopApproachAnimation()
    }

    // MARK: - Demo helpers

    func simulateTimerExpiry() {
        triggerSOS()
    }

    func simulateSOSReceived() {
        receivedSOSFrom = "Bob Smith"
        sosIsResponding = false
        sosDistanceMeters = 120.0
        // Port Stewart area — slightly offset from base camp
        sosGPSLat = -14.7031
        sosGPSLon = 143.7089
        sosBearing = 42.0
        startBearingAnimation()
    }

    // MARK: - Private — check-in timer

    private func fireTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                    self.triggerSOS()
                }
            }
        }
    }

    // MARK: - Private — alarm

    private func startAlarm() {
        fireAlarmSound()
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.fireAlarmSound() }
        }
    }

    private func fireAlarmSound() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(1005)
    }

    private func stopAlarm() {
        alarmTimer?.invalidate()
        alarmTimer = nil
    }

    // MARK: - Private — bearing oscillation

    private func startBearingAnimation() {
        bearingTimer?.invalidate()
        bearingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.sosDistanceMeters > 5 else { return } // lock when found
                let t = Date().timeIntervalSinceReferenceDate
                // Amplitude narrows as distance shrinks: far=25°, near=3°, found=0°
                let amplitude = min(25.0, max(3.0, self.sosDistanceMeters * 0.22))
                // Speed also slows as we close in (feel of "locking on")
                let speed = self.sosDistanceMeters > 40 ? 1.1 : 0.55
                self.sosBearing = 42 + sin(t * speed) * amplitude
            }
        }
    }

    private func stopBearingAnimation() {
        bearingTimer?.invalidate()
        bearingTimer = nil
    }

    // MARK: - Private — approach animation

    private func startApproachAnimation() {
        approachTimer?.invalidate()
        // Tick every 2.5 seconds — moves 5-18m closer each tick
        approachTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.sosDistanceMeters > 0 else {
                    self.approachTimer?.invalidate()
                    self.approachTimer = nil
                    return
                }
                // Step size proportional to distance — big steps far out, tiny steps up close
                let maxStep = min(18.0, self.sosDistanceMeters * 0.22)
                let minStep = max(1.0, self.sosDistanceMeters * 0.06)
                let step = Double.random(in: minStep...maxStep)
                self.sosDistanceMeters = max(0, self.sosDistanceMeters - step)

                // GPS drift — starts large, tightens as we close in (signal getting clearer)
                let coordNoise = (self.sosDistanceMeters / 120.0) * 0.0004
                self.sosGPSLat += Double.random(in: -coordNoise...coordNoise)
                self.sosGPSLon += Double.random(in: -coordNoise...coordNoise)
            }
        }
    }

    private func stopApproachAnimation() {
        approachTimer?.invalidate()
        approachTimer = nil
    }

    // MARK: - Private — GPS formatting

    private func formatDMS(_ decimal: Double, isLat: Bool) -> String {
        let abs = Swift.abs(decimal)
        let deg = Int(abs)
        let minFull = (abs - Double(deg)) * 60
        let min = Int(minFull)
        let sec = (minFull - Double(min)) * 60
        let hemisphere: String
        if isLat {
            hemisphere = decimal >= 0 ? "N" : "S"
        } else {
            hemisphere = decimal >= 0 ? "E" : "W"
        }
        return String(format: "%d°%02d'%04.1f\"%@", deg, min, sec, hemisphere)
    }

    // MARK: - Private — notifications

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Safety Check-In Required"
            content.body = "Your check-in timer has expired. Please confirm you are safe."
            content.sound = .defaultCritical
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: self.totalTime, repeats: false)
            let request = UNNotificationRequest(identifier: "safety.checkin", content: content, trigger: trigger)
            center.add(request)
        }
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["safety.checkin"])
    }
}
