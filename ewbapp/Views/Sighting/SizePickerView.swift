import SwiftUI

struct SizePickerView: View {
    @Binding var selectedSize: InfestationSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Infestation Size")
                .font(.headline)
            HStack(spacing: 8) {
                ForEach(InfestationSize.allCases, id: \.self) { size in
                    SizeButton(size: size, isSelected: selectedSize == size) {
                        selectedSize = size
                    }
                }
            }
        }
    }
}

struct SizeButton: View {
    let size: InfestationSize
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(size.displayName)
                    .font(.headline)
                Text(size.areaDescription)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(isSelected ? Color.green : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
