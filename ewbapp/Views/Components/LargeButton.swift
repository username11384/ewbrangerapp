import SwiftUI

struct LargeButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var color: Color = .dsPrimary

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpace.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.85)
                }
                Text(title)
                    .font(DSFont.subhead)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isEnabled ? color : Color.dsInkMuted)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            .shadow(color: (isEnabled ? color : Color.clear).opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(.plain)
    }
}
