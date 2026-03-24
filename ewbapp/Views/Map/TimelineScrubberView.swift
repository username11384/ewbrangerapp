import SwiftUI

struct TimelineScrubberView: View {
    @Binding var date: Date
    let range: ClosedRange<Date>
    let isPlaying: Bool
    let onTogglePlay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTogglePlay) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 32, height: 32)
            }
            VStack(alignment: .leading, spacing: 2) {
                Slider(value: Binding(
                    get: {
                        date.timeIntervalSince1970
                    },
                    set: { val in
                        date = Date(timeIntervalSince1970: val)
                    }
                ), in: range.lowerBound.timeIntervalSince1970...range.upperBound.timeIntervalSince1970)
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}
