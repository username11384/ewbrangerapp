import Foundation

// MARK: - HerbicideDatabase
// Static herbicide reference data for northern Queensland invasive weed control.
// All data is compiled from Queensland Government, APVMA, and standard agronomic
// sources relevant to Cape York / tropical savanna conditions.
// No network or CoreData dependency — offline-safe by design.

struct Herbicide: Identifiable {
    let id: String
    let name: String
    let activeIngredient: String
    /// Common product names used in Queensland
    let commonProducts: [String]
    /// Invasive species this herbicide effectively controls (matches InvasiveSpecies.displayName)
    let targetSpecies: [String]
    /// Names of other herbicides that must NOT be tank-mixed with this one
    let notCompatibleWith: [String]
    /// Key weather/timing application constraint
    let weatherConstraints: String
    /// Required personal protective equipment
    let ppeRequired: [String]
    /// Typical foliar dilution rate in mL per 10 L of water
    let dilutionRateMlPer10L: Double
    /// Application method notes specific to this herbicide
    let applicationNotes: String
}

// MARK: - Database

enum HerbicideDatabase {

    static let all: [Herbicide] = [

        Herbicide(
            id: "glyphosate",
            name: "Glyphosate",
            activeIngredient: "Glyphosate 360 g/L (SL)",
            commonProducts: ["Roundup Biactive", "Weedmaster Duo", "Glyphosate 360"],
            targetSpecies: [
                "Lantana",
                "Rubber Vine",
                "Sicklepod",
                "Giant Rat's Tail Grass",
                "Pond Apple"
            ],
            notCompatibleWith: ["Metsulfuron"],
            weatherConstraints: "Do not apply if rain expected within 4 hours. Avoid application in temperatures above 35 °C or during drought stress. Best applied in calm conditions to minimise drift.",
            ppeRequired: ["Chemical-resistant gloves", "Eye protection", "Long-sleeved clothing"],
            dilutionRateMlPer10L: 100,
            applicationNotes: "Foliar spray: add a non-ionic surfactant (0.25% v/v) to improve uptake. Allow 7–10 days for full effect before follow-up assessment. Do not use near waterways — use Access or Garlon alternatives instead."
        ),

        Herbicide(
            id: "metsulfuron",
            name: "Metsulfuron",
            activeIngredient: "Metsulfuron-methyl 600 g/kg (WG)",
            commonProducts: ["Brushoff", "Metsulfuron 600 DF", "Ally"],
            targetSpecies: [
                "Lantana",
                "Sicklepod",
                "Prickly Acacia"
            ],
            notCompatibleWith: ["Glyphosate", "Picloram"],
            weatherConstraints: "Do not apply if rain expected within 1 hour. Soil activity — do not apply before heavy rain events. Avoid use near susceptible crops or native legumes.",
            ppeRequired: ["Chemical-resistant gloves", "Eye protection", "Dust mask when handling concentrate"],
            dilutionRateMlPer10L: 1.5,
            applicationNotes: "Highly effective on broad-leaf weeds at very low rates. Add a non-ionic surfactant. Residual soil activity — observe re-sowing withholding periods. Restricted near waterways due to persistence."
        ),

        Herbicide(
            id: "triclopyr",
            name: "Triclopyr",
            activeIngredient: "Triclopyr 600 g/L (EC)",
            commonProducts: ["Garlon 600", "Triclopyr 600EC", "Starane Advanced"],
            targetSpecies: [
                "Lantana",
                "Rubber Vine",
                "Pond Apple",
                "Prickly Acacia"
            ],
            notCompatibleWith: ["Aminopyralid"],
            weatherConstraints: "Do not apply if rain expected within 2 hours. Avoid application during strong winds. Do not apply when temperatures exceed 30 °C — product volatilises and can drift to non-target plants.",
            ppeRequired: ["Chemical-resistant gloves", "Eye protection", "Respirator (mixing concentrate)", "Protective footwear"],
            dilutionRateMlPer10L: 130,
            applicationNotes: "Preferred for basal bark and cut-stump application in diesel or penetrant oil carrier. Excellent on woody shrubs and vines. Safe for use near waterways when used at label rates — good for riparian Rubber Vine and Pond Apple control."
        ),

        Herbicide(
            id: "picloram",
            name: "Picloram",
            activeIngredient: "Picloram 44.7 g/L + Triclopyr 44.7 g/L (SL)",
            commonProducts: ["Tordon 75-D", "Access", "Grazon Extra"],
            targetSpecies: [
                "Lantana",
                "Rubber Vine",
                "Prickly Acacia",
                "Pond Apple"
            ],
            notCompatibleWith: ["Metsulfuron", "Aminopyralid"],
            weatherConstraints: "Do not apply if rain expected within 1 hour. Significant soil persistence — do not use on sandy soils near waterways. Avoid spray drift. Not to be used in areas where susceptible crops are grown nearby.",
            ppeRequired: ["Chemical-resistant gloves", "Full face shield", "Respirator", "Protective clothing", "Protective footwear"],
            dilutionRateMlPer10L: 100,
            applicationNotes: "Highly effective stem injection and cut-stump herbicide for large woody weeds. Tordon 75-D uses diesel carrier for undiluted basal bark application. Picloram component provides residual soil activity — prevents regrowth. Withholding period applies for livestock grazing."
        ),

        Herbicide(
            id: "aminopyralid",
            name: "Aminopyralid",
            activeIngredient: "Aminopyralid 300 g/L (SL)",
            commonProducts: ["Grazon Extra", "Vigilant II Gel", "Broadstrike"],
            targetSpecies: [
                "Lantana",
                "Sicklepod",
                "Prickly Acacia"
            ],
            notCompatibleWith: ["Triclopyr", "Picloram"],
            weatherConstraints: "Do not apply if rain expected within 1 hour. Very high soil persistence — do not use in cultivation areas or where soil runoff enters waterways. Composting restriction: do not use treated plant material as compost or mulch.",
            ppeRequired: ["Chemical-resistant gloves", "Eye protection", "Long-sleeved clothing"],
            dilutionRateMlPer10L: 50,
            applicationNotes: "Vigilant II Gel formulation suitable for small cut-stumps and individual stem treatment — minimises non-target exposure. Aminopyralid is highly persistent; observe all grazing and crop re-sowing withholding periods. Do not allow treated material to enter compost systems."
        ),

        Herbicide(
            id: "fluroxypyr",
            name: "Fluroxypyr",
            activeIngredient: "Fluroxypyr 200 g/L (EC)",
            commonProducts: ["Starane 200", "Fluroxypyr 200EC", "Hotshot"],
            targetSpecies: [
                "Giant Rat's Tail Grass",
                "Sicklepod",
                "Lantana"
            ],
            notCompatibleWith: [],
            weatherConstraints: "Do not apply if rain expected within 1 hour. Avoid application in extreme heat (above 35 °C). Effective at temperatures above 15 °C.",
            ppeRequired: ["Chemical-resistant gloves", "Eye protection"],
            dilutionRateMlPer10L: 60,
            applicationNotes: "Selective for broad-leaf weeds in pasture situations — does not affect most grasses. Useful where Giant Rat's Tail Grass management involves pasture renovation. Compatible with most broadleaf herbicides when mixed fresh. Always mix just before use."
        ),

        Herbicide(
            id: "haloxyfop",
            name: "Haloxyfop",
            activeIngredient: "Haloxyfop-P 520 g/L (EC)",
            commonProducts: ["Verdict 520", "Haloxyfop 520EC"],
            targetSpecies: [
                "Giant Rat's Tail Grass"
            ],
            notCompatibleWith: [],
            weatherConstraints: "Do not apply if rain expected within 1 hour. Most effective when grass is actively growing. Avoid application in drought stress conditions.",
            ppeRequired: ["Chemical-resistant gloves", "Eye protection", "Long-sleeved clothing"],
            dilutionRateMlPer10L: 40,
            applicationNotes: "Highly selective grass-specific herbicide — will not harm broad-leaf plants or native trees. Best option for Giant Rat's Tail Grass growing within native vegetation. Requires addition of a crop oil concentrate (1% v/v). Allow 3–4 weeks for full effect. Post-emergent only."
        ),

        Herbicide(
            id: "imazapyr",
            name: "Imazapyr",
            activeIngredient: "Imazapyr 250 g/L (SL)",
            commonProducts: ["Arsenal Xtra", "Imazapyr 250 SL"],
            targetSpecies: [
                "Rubber Vine",
                "Pond Apple",
                "Giant Rat's Tail Grass"
            ],
            notCompatibleWith: ["Metsulfuron", "Glyphosate"],
            weatherConstraints: "Do not apply if rain expected within 2 hours. Significant soil residual activity — use only in bushland, not near crops or desirable native pasture. Do not use on or near waterways.",
            ppeRequired: ["Chemical-resistant gloves", "Eye protection", "Respirator (concentrate handling)", "Protective clothing"],
            dilutionRateMlPer10L: 30,
            applicationNotes: "Soil and foliar activity — very effective for stem injection of large Rubber Vine and Pond Apple. Residual soil activity suppresses seedling emergence for 12–18 months. Ideal for multi-year control programs. Not for use near desirable vegetation due to root uptake."
        ),
    ]

    // MARK: - Query Helpers

    /// Returns all herbicides that target the given species display name.
    static func herbicides(for speciesName: String) -> [Herbicide] {
        all.filter { $0.targetSpecies.contains(speciesName) }
    }

    /// Returns a compatibility result for two herbicides.
    static func compatibility(between a: Herbicide, and b: Herbicide) -> CompatibilityResult {
        if a.id == b.id {
            return .sameProduct
        }
        let aIncompatibleWithB = a.notCompatibleWith.contains(b.name)
        let bIncompatibleWithA = b.notCompatibleWith.contains(a.name)
        if aIncompatibleWithB || bIncompatibleWithA {
            return .incompatible
        }
        return .compatible
    }

    enum CompatibilityResult {
        case compatible
        case incompatible
        case sameProduct
    }
}
