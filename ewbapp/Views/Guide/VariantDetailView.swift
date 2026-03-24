import SwiftUI

struct VariantDetailView: View {
    let info: LantanaVariantContent.VariantInfo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Colour swatch (placeholder — in prod would show HEIF photo from assets)
                RoundedRectangle(cornerRadius: 12)
                    .fill(info.variant.color.gradient)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Text(info.commonName)
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text(info.scientificNote)
                                .font(.subheadline.italic())
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )

                // Biocontrol warning banner (pink variant during wet season)
                if info.variant.hasBiocontrolConcern {
                    SeasonalAlertBanner(alert: SeasonalAlert(
                        title: "Check for Biocontrol Insects",
                        message: "During the wet season (Nov–Mar), check for lantana bug before applying chemicals to pink Lantana.",
                        severity: .warning
                    ))
                }

                // Features
                VStack(alignment: .leading, spacing: 8) {
                    Text("Identifying Features")
                        .font(.headline)
                    Text(info.distinguishingFeatures)
                }

                // Control methods
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Control")
                        .font(.headline)
                    ForEach(info.controlMethods, id: \.self) { method in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: method.systemIconName)
                                    .foregroundColor(.green)
                                    .frame(width: 20, height: 20)
                                Text(method.displayName)
                                    .font(.subheadline.bold())
                            }
                            Text(method.instructions)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }

                // Seasonal notes
                if let seasonal = info.seasonalNotes {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seasonal Notes")
                            .font(.headline)
                        Text(seasonal)
                            .font(.callout)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(info.commonName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
