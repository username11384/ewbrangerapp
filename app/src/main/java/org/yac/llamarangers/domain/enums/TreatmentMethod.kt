package org.yac.llamarangers.domain.enums

enum class TreatmentMethod(val displayName: String, val instructions: String) {
    CUT_STUMP(
        displayName = "Cut Stump",
        instructions = "Cut stem close to ground. Immediately apply Garlon 600 undiluted to the cut surface. Apply within 15 seconds of cutting."
    ),
    SPLAT_GUN(
        displayName = "Splat Gun",
        instructions = "Apply Vigilant herbicide gel directly to cut or wound in stem. One application per stem. Effective year-round."
    ),
    FOLIAR_SPRAY(
        displayName = "Foliar Spray",
        instructions = "Mix Garlon 600 at 10 mL per litre water. Spray all foliage to wet point. Best applied during active growth (wet season)."
    ),
    BASAL_BARK(
        displayName = "Basal Bark",
        instructions = "Mix Garlon 600 at 100 mL per litre diesel. Apply to base of stem 30 cm from ground. Effective on stems < 4 cm diameter."
    )
}
