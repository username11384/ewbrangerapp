#if canImport(UIKit)
import UIKit
#endif
import Combine
import SwiftUI
import AVFoundation

// MARK: - VoiceNoteRecorder

struct VoiceNoteRecorder: View {
    @Binding var audioFilePath: String?

    @StateObject private var recorder = VoiceNoteRecorderModel()

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            Text("Voice Note (optional)")
                .font(DSFont.headline)
                .foregroundStyle(Color.dsInk)

            HStack(spacing: DSSpace.md) {
                // Record / stop button
                if recorder.state != .recorded {
                    Button {
                        if recorder.state == .idle {
                            recorder.startRecording()
                        } else {
                            recorder.stopRecording { path in
                                audioFilePath = path
                            }
                        }
                    } label: {
                        HStack(spacing: DSSpace.sm) {
                            Image(systemName: recorder.state == .recording ? "stop.circle.fill" : "mic.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(recorder.state == .recording ? Color.dsStatusActive : Color.dsPrimary)

                            Text(recorder.state == .recording ? "Stop" : "Record")
                                .font(DSFont.callout)
                                .foregroundStyle(recorder.state == .recording ? Color.dsStatusActive : Color.dsPrimary)

                            if recorder.state == .recording {
                                Text(recorder.durationString)
                                    .font(DSFont.mono)
                                    .foregroundStyle(Color.dsStatusActive)
                                    .monospacedDigit()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DSSpace.md)
                        .frame(height: 44)
                        .background(
                            recorder.state == .recording
                                ? Color.dsStatusActiveSoft
                                : Color.dsPrimarySoft
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                .strokeBorder(
                                    recorder.state == .recording
                                        ? Color.dsStatusActive.opacity(0.4)
                                        : Color.dsPrimary.opacity(0.25),
                                    lineWidth: 0.75
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Playback + delete when recorded
                if recorder.state == .recorded {
                    Button {
                        recorder.togglePlayback()
                    } label: {
                        HStack(spacing: DSSpace.sm) {
                            Image(systemName: recorder.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.dsPrimary)
                            Text(recorder.isPlaying ? "Pause" : "Play note")
                                .font(DSFont.callout)
                                .foregroundStyle(Color.dsPrimary)
                            Spacer()
                            Text(recorder.durationString)
                                .font(DSFont.mono)
                                .foregroundStyle(Color.dsInk3)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, DSSpace.md)
                        .frame(height: 44)
                        .background(Color.dsPrimarySoft)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                .strokeBorder(Color.dsPrimary.opacity(0.25), lineWidth: 0.75)
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Button {
                        recorder.deleteRecording()
                        audioFilePath = nil
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.dsStatusActive)
                            .frame(width: 44, height: 44)
                            .background(Color.dsStatusActiveSoft)
                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            if recorder.state == .recording {
                HStack(spacing: DSSpace.xs) {
                    Circle()
                        .fill(Color.dsStatusActive)
                        .frame(width: 7, height: 7)
                    Text("Recording…")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.dsStatusActive)
                }
            }
        }
        .onDisappear {
            recorder.cleanup()
        }
    }
}

// MARK: - VoiceNoteRecorderModel

@MainActor
final class VoiceNoteRecorderModel: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    enum RecorderState { case idle, recording, recorded }

    @Published var state: RecorderState = .idle
    @Published var isPlaying: Bool = false
    @Published var durationString: String = "0:00"

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var currentFilePath: String?
    private var timer: Timer?
    private var elapsed: TimeInterval = 0
    private var recordedDuration: TimeInterval = 0

    // MARK: Recording

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            return
        }

        let filename = "\(UUID().uuidString).m4a"
        let url = documentsURL().appendingPathComponent(filename)
        currentFilePath = url.path

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        guard let recorder = try? AVAudioRecorder(url: url, settings: settings) else { return }
        recorder.delegate = self
        recorder.record()
        audioRecorder = recorder

        elapsed = 0
        durationString = "0:00"
        state = .recording
        startTimer()
    }

    func stopRecording(completion: (String?) -> Void) {
        audioRecorder?.stop()
        audioRecorder = nil
        stopTimer()
        recordedDuration = elapsed
        durationString = formatDuration(recordedDuration)
        state = .recorded
        completion(currentFilePath)
    }

    // MARK: Playback

    func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
            stopTimer()
        } else {
            guard let path = currentFilePath else { return }
            let url = URL(fileURLWithPath: path)
            guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
            player.delegate = self
            player.play()
            audioPlayer = player
            isPlaying = true
            elapsed = 0
            startPlaybackTimer()
        }
    }

    // MARK: Delete

    func deleteRecording() {
        audioPlayer?.stop()
        audioPlayer = nil
        stopTimer()
        if let path = currentFilePath {
            try? FileManager.default.removeItem(atPath: path)
        }
        currentFilePath = nil
        state = .idle
        isPlaying = false
        elapsed = 0
        durationString = "0:00"
    }

    // MARK: Cleanup

    func cleanup() {
        audioPlayer?.stop()
        audioRecorder?.stop()
        stopTimer()
    }

    // MARK: AVAudioRecorderDelegate

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}

    // MARK: AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopTimer()
            self.durationString = self.formatDuration(self.recordedDuration)
        }
    }

    // MARK: Timer helpers

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.elapsed += 1
                self.durationString = self.formatDuration(self.elapsed)
            }
        }
    }

    private func startPlaybackTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.elapsed += 1
                self.durationString = self.formatDuration(self.elapsed)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
