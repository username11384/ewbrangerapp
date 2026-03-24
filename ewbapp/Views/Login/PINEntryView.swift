import SwiftUI

struct PINEntryView: View {
    @Binding var enteredPIN: String
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    private let digits = [["1","2","3"],["4","5","6"],["7","8","9"],["","0","⌫"]]

    var body: some View {
        VStack(spacing: 24) {
            // PIN dots
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < enteredPIN.count ? Color.green : Color.secondary.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
            // Keypad
            VStack(spacing: 12) {
                ForEach(digits, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { digit in
                            if digit.isEmpty {
                                Color.clear.frame(width: 90, height: 70)
                            } else {
                                Button {
                                    if digit == "⌫" { onDelete() } else { onDigit(digit) }
                                } label: {
                                    Text(digit)
                                        .font(.title2.bold())
                                        .frame(width: 90, height: 70)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}
