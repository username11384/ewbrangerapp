import SwiftUI

struct LargeButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var color: Color = .green

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isEnabled ? color : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
    }
}
