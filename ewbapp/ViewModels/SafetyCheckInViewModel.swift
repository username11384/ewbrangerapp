import Foundation
import UserNotifications
import Combine

@MainActor
final class SafetyCheckInViewModel: ObservableObject {
    @Published var isActive = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var intervalMinutes: Int = 60

    private var timer: Timer?
    private var totalTime: TimeInterval { TimeInterval(intervalMinutes * 60) }

    // MARK: - Computed

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return timeRemaining / totalTime
    }

    var timeFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Actions

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

    // MARK: - Private

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
                    self.isActive = false
                }
            }
        }
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Safety Check-In Required"
            content.body = "Your check-in timer has expired. Please confirm you are safe."
            content.sound = .defaultCritical

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: self.totalTime,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "safety.checkin",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["safety.checkin"])
    }
}
