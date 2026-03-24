import SwiftUI

struct VariantPickerView: View {
    @Binding var selectedVariant: LantanaVariant?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Variant")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LantanaVariant.allCases, id: \.self) { variant in
                        VariantCard(
                            variant: variant,
                            isSelected: selectedVariant == variant
                        ) {
                            selectedVariant = variant
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

struct VariantCard: View {
    let variant: LantanaVariant
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Colour swatch (placeholder for bundled photo)
                RoundedRectangle(cornerRadius: 8)
                    .fill(variant.color)
                    .frame(width: 70, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                    )
                Text(variant.displayName)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .frame(height: 30, alignment: .top)
            }
            .frame(width: 80)
            .padding(8)
            .background(isSelected ? Color(.systemGray5) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
