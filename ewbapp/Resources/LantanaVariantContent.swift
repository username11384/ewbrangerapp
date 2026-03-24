import Foundation

struct LantanaVariantContent {
    struct VariantInfo {
        let variant: LantanaVariant
        let commonName: String
        let scientificNote: String
        let imageName: String // Asset catalog name
        let distinguishingFeatures: String
        let controlMethods: [TreatmentMethod]
        let seasonalNotes: String?
    }

    static let all: [VariantInfo] = [
        VariantInfo(
            variant: .pink,
            commonName: "Pink Lantana",
            scientificNote: "Lantana camara (pink form)",
            imageName: "lantana_pink",
            distinguishingFeatures: "Soft pink flowers, often fading to yellow centres. Compact shrub to 2m. Common in disturbed roadsides and cleared areas.",
            controlMethods: [.foliarSpray, .splatGun],
            seasonalNotes: "Check for lantana bug (Aconophora compressa) before spraying during wet season (Nov–Mar)."
        ),
        VariantInfo(
            variant: .red,
            commonName: "Red Lantana",
            scientificNote: "Lantana camara (red form)",
            imageName: "lantana_red",
            distinguishingFeatures: "Deep red-orange flowers aging to darker red. Most vigorous spreader. Toxic black berries attractive to birds.",
            controlMethods: [.cutStump, .basalBark],
            seasonalNotes: nil
        ),
        VariantInfo(
            variant: .pinkEdgedRed,
            commonName: "Pink-Edged Red Lantana",
            scientificNote: "Lantana camara (hybrid form)",
            imageName: "lantana_pink_edged_red",
            distinguishingFeatures: "Pink outer petals with red or orange centre. Hybrid characteristics, often larger than pure variants.",
            controlMethods: [.cutStump, .foliarSpray],
            seasonalNotes: nil
        ),
        VariantInfo(
            variant: .orange,
            commonName: "Orange Lantana",
            scientificNote: "Lantana camara (orange form)",
            imageName: "lantana_orange",
            distinguishingFeatures: "Bright orange to yellow-orange flowers. Common along watercourses and creek edges. Good spreader via waterways.",
            controlMethods: [.foliarSpray, .basalBark],
            seasonalNotes: nil
        ),
        VariantInfo(
            variant: .white,
            commonName: "White Lantana",
            scientificNote: "Lantana camara (white form)",
            imageName: "lantana_white",
            distinguishingFeatures: "White to cream flowers, sometimes with faint yellow centres. Less vigorous but still invasive. Often found in shaded areas.",
            controlMethods: [.foliarSpray, .splatGun],
            seasonalNotes: nil
        ),
        VariantInfo(
            variant: .unknown,
            commonName: "Unknown Variant",
            scientificNote: "Lantana camara (unidentified)",
            imageName: "lantana_unknown",
            distinguishingFeatures: "Variant not clearly identifiable from field observation. Log and treat as per nearest visual match.",
            controlMethods: [.foliarSpray],
            seasonalNotes: nil
        )
    ]
}
