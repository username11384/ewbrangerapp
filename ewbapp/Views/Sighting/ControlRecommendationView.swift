import SwiftUI

struct ControlRecommendationView: View {
    let recommendation: String

    var body: some View {
        HStack(spacing: DSSpace.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.dsPrimary)
            Text(recommendation)
                .font(DSFont.callout)
                .foregroundStyle(Color.dsInk2)
        }
        .padding(DSSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsPrimarySoft)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .strokeBorder(Color.dsPrimary.opacity(0.2), lineWidth: 0.75)
        )
    }
}
