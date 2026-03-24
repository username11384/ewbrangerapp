import SwiftUI

struct VariantColourDot: View {
    let variant: LantanaVariant
    var size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(variant.color)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 0.5))
    }
}
