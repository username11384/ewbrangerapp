import SwiftUI

struct VariantGuideView: View {
    var body: some View {
        NavigationStack {
            List(LantanaVariantContent.all, id: \.variant) { info in
                NavigationLink(destination: VariantDetailView(info: info)) {
                    HStack(spacing: 14) {
                        VariantColourDot(variant: info.variant, size: 20)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(info.commonName)
                                .font(.headline)
                            Text(String(info.controlMethods.map { $0.displayName }.joined(separator: ", ")))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Variant Guide")
        }
    }
}
