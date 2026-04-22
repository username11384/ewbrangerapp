import Foundation

// MARK: - PhenologyAlert
// Month-matched phenology alerts shown inline at log time.
// Purely UI data — no persistence required.

struct PhenologyAlert: Equatable {
    let speciesName: String          // Must match InvasiveSpecies.rawValue
    let month: Int                   // 1–12
    let phase: String                // e.g. "Flowering", "Seeding", "Peak Growth", "Dormant"
    let actionRecommended: String
    let urgencyLevel: UrgencyLevel

    enum UrgencyLevel: String {
        case routine  = "Routine"
        case priority = "Priority"
        case urgent   = "Urgent"
    }
}

// MARK: - PhenologyAlertStore

enum PhenologyAlertStore {

    // All phenology alerts keyed to InvasiveSpecies rawValue strings and months.
    // Months reflect Cape York / tropical Queensland seasonality.
    static let all: [PhenologyAlert] = [

        // ── Lantana (Lantana camara) ─────────────────────────────────────────
        // Autumn treatment window: Apr–May (peak efficacy for foliar / basal bark)
        PhenologyAlert(speciesName: "lantana", month: 4,  phase: "Autumn Treatment Window",
                       actionRecommended: "Optimal time for foliar spray and basal bark treatment. Apply before new growth hardens.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "lantana", month: 5,  phase: "Autumn Treatment Window",
                       actionRecommended: "Final weeks of peak treatment window. Prioritise heavy infestations before dry season.",
                       urgencyLevel: .urgent),
        // Flowering / berrying — wet season biocontrol concern
        PhenologyAlert(speciesName: "lantana", month: 11, phase: "Flowering",
                       actionRecommended: "Check for Lantana bug (Aconophora compressa) before spraying pink-flowered plants.",
                       urgencyLevel: .priority),
        PhenologyAlert(speciesName: "lantana", month: 12, phase: "Flowering",
                       actionRecommended: "Biocontrol insects active. Delay foliar spray on pink-flowered plants if bugs present.",
                       urgencyLevel: .priority),
        PhenologyAlert(speciesName: "lantana", month: 1,  phase: "Peak Growth",
                       actionRecommended: "Rapid wet season growth. Record spread extent. Hold foliar spray near biocontrol colonies.",
                       urgencyLevel: .routine),
        PhenologyAlert(speciesName: "lantana", month: 2,  phase: "Fruiting",
                       actionRecommended: "Berries ripening — bird dispersal risk elevated. Prioritise removal of fruiting plants near creek lines.",
                       urgencyLevel: .priority),
        PhenologyAlert(speciesName: "lantana", month: 3,  phase: "Late Wet / Fruiting",
                       actionRecommended: "Continue monitoring dispersal. Plan autumn treatment campaign for next month.",
                       urgencyLevel: .routine),

        // ── Rubber Vine (Cryptostegia grandiflora) ──────────────────────────
        // Flowering Aug–Oct — best ID and pre-seed treatment window
        PhenologyAlert(speciesName: "rubberVine", month: 8,  phase: "Flowering",
                       actionRecommended: "Peak flowering — easiest time to locate plants. Map new infestations and begin treatment.",
                       urgencyLevel: .priority),
        PhenologyAlert(speciesName: "rubberVine", month: 9,  phase: "Flowering",
                       actionRecommended: "Flowering peak continues. Use stem injection near waterways to minimise herbicide runoff.",
                       urgencyLevel: .priority),
        PhenologyAlert(speciesName: "rubberVine", month: 10, phase: "Seeding",
                       actionRecommended: "Urgent — seed pods forming. Treat before pod split to prevent floodwater dispersal downstream.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "rubberVine", month: 11, phase: "Seed Dispersal",
                       actionRecommended: "Pods may be splitting. Check upstream reaches. Remove seed pods before wet season flood events.",
                       urgencyLevel: .urgent),

        // ── Prickly Acacia (Vachellia nilotica) ─────────────────────────────
        // Flowering in dry season; pods drop May–Sep
        PhenologyAlert(speciesName: "pricklyAcacia", month: 5,  phase: "Pod Formation",
                       actionRecommended: "Pods beginning to form. Prioritise removal of seed-bearing trees before pod drop. Check for seed weevil biocontrol.",
                       urgencyLevel: .priority),
        PhenologyAlert(speciesName: "pricklyAcacia", month: 6,  phase: "Pod Drop",
                       actionRecommended: "Urgent seed dispersal period. Focus cut-stump or stem injection on heaviest-seeding trees first.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "pricklyAcacia", month: 7,  phase: "Pod Drop",
                       actionRecommended: "Pods falling — seed bank building rapidly. Mechanical removal of pods from ground reduces recruitment.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "pricklyAcacia", month: 8,  phase: "Late Pod Drop",
                       actionRecommended: "Continue removal operations. Inspect creek lines and floodplains for new seedlings post-drop.",
                       urgencyLevel: .priority),
        PhenologyAlert(speciesName: "pricklyAcacia", month: 9,  phase: "Dormant / Post-Drop",
                       actionRecommended: "Treat stumps and residual trees before wet season. Record locations of heavy seedbanks for follow-up.",
                       urgencyLevel: .routine),

        // ── Sicklepod (Senna obtusifolia) ────────────────────────────────────
        // Annual — germinates and flowers in wet season (Nov–Apr)
        PhenologyAlert(speciesName: "sicklepod", month: 11, phase: "Germination",
                       actionRecommended: "Seedlings emerging with first rains. Mechanical removal is most effective now (plants < 30 cm).",
                       urgencyLevel: .priority),
        PhenologyAlert(speciesName: "sicklepod", month: 12, phase: "Peak Growth",
                       actionRecommended: "Rapid growth phase. Remove before flowering to break the seed cycle. Hand-pull or slash young plants.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "sicklepod", month: 1,  phase: "Flowering",
                       actionRecommended: "Plants flowering — urgent removal before seed set. Foliar spray effective on larger plants.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "sicklepod", month: 2,  phase: "Seeding",
                       actionRecommended: "Seeds forming in curved pods. Prevent seed maturation — remove flowering/seeding plants immediately.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "sicklepod", month: 3,  phase: "Seed Ripening",
                       actionRecommended: "Late wet season — mature seeds spreading. Record density for comparison with previous year.",
                       urgencyLevel: .priority),

        // ── Giant Rat's Tail Grass (Sporobolus pyramidalis) ──────────────────
        // Seed heads ripen late dry season Aug–Oct
        PhenologyAlert(speciesName: "giantRatsTailGrass", month: 8,  phase: "Seeding",
                       actionRecommended: "Seed heads ripening. Slash or burn before seed set to significantly reduce next season's spread.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "giantRatsTailGrass", month: 9,  phase: "Peak Seeding",
                       actionRecommended: "Peak seed production. Late dry season burn can reduce established clumps — coordinate with fire plan.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "giantRatsTailGrass", month: 10, phase: "Seed Dispersal",
                       actionRecommended: "Seeds dispersing via wind and machinery. Avoid slashing at this stage — it spreads seed. Apply foliar spray.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "giantRatsTailGrass", month: 11, phase: "Wet Season Green-Up",
                       actionRecommended: "New growth emerging after rains. Foliar spray effective on actively growing plants. Wet season burn can also be planned.",
                       urgencyLevel: .priority),

        // ── Pond Apple (Annona glabra) ────────────────────────────────────────
        // Fruits ripen and float late wet season / early dry
        PhenologyAlert(speciesName: "pondApple", month: 12, phase: "Flowering",
                       actionRecommended: "Plants flowering. Map locations of upstream trees to prioritise treatment before fruiting.",
                       urgencyLevel: .routine),
        PhenologyAlert(speciesName: "pondApple", month: 1,  phase: "Fruit Development",
                       actionRecommended: "Fruit developing. Plan stem injection now — treat before fruit ripens to prevent water dispersal.",
                       urgencyLevel: .priority),
        PhenologyAlert(speciesName: "pondApple", month: 2,  phase: "Fruiting",
                       actionRecommended: "Fruit maturing — floating dispersal risk increasing with flood events. Prioritise upstream removal urgently.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "pondApple", month: 3,  phase: "Peak Fruiting",
                       actionRecommended: "Peak fruit drop. Fruit floats long distances. Focus on upstream plants. Use stem injection near waterways.",
                       urgencyLevel: .urgent),
        PhenologyAlert(speciesName: "pondApple", month: 4,  phase: "Late Fruiting",
                       actionRecommended: "Fruit drop continuing into early dry season. Continue upstream removal and inspect downstream for new recruits.",
                       urgencyLevel: .priority),
    ]

    /// Returns the first alert matching `species.rawValue` for the given month, or nil.
    static func alert(for species: InvasiveSpecies, month: Int) -> PhenologyAlert? {
        all.first { $0.speciesName == species.rawValue && $0.month == month }
    }
}
