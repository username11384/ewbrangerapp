package org.yac.llamarangers.domain.enums

import androidx.compose.ui.graphics.Color

enum class LantanaVariant(
    val displayName: String,
    val color: Color,
    val distinguishingFeatures: String,
    val controlMethods: List<TreatmentMethod>
) {
    PINK(
        displayName = "Pink",
        color = Color(0xFFFF69B5),
        distinguishingFeatures = "Pale pink flowers with yellow centre. Soft stem hairs. Wet season: watch for lantana bug damage.",
        controlMethods = listOf(TreatmentMethod.FOLIAR_SPRAY, TreatmentMethod.BASAL_BARK)
    ),
    RED(
        displayName = "Red",
        color = Color(0xFFDC143C),
        distinguishingFeatures = "Bright red/orange flowers. Woody stems. Most common variant in Port Stewart region.",
        controlMethods = listOf(TreatmentMethod.CUT_STUMP, TreatmentMethod.SPLAT_GUN)
    ),
    PINK_EDGED_RED(
        displayName = "Pink-Edged Red",
        color = Color(0xFFE64073),
        distinguishingFeatures = "Red flowers with distinct pink outer petal edges. Intermediate growth habit.",
        controlMethods = listOf(TreatmentMethod.FOLIAR_SPRAY, TreatmentMethod.CUT_STUMP)
    ),
    ORANGE(
        displayName = "Orange",
        color = Color(0xFFFF8C00),
        distinguishingFeatures = "Orange-yellow flowers. Sprawling growth. Often found along creek lines.",
        controlMethods = listOf(TreatmentMethod.BASAL_BARK, TreatmentMethod.FOLIAR_SPRAY)
    ),
    WHITE(
        displayName = "White",
        color = Color(0xFFF0F0F0),
        distinguishingFeatures = "White flowers, sometimes with pale yellow. Less aggressive than red/pink variants.",
        controlMethods = listOf(TreatmentMethod.FOLIAR_SPRAY)
    ),
    UNKNOWN(
        displayName = "Unknown",
        color = Color(0xFF888888),
        distinguishingFeatures = "Variant not identified. Record photo for later classification.",
        controlMethods = listOf(TreatmentMethod.FOLIAR_SPRAY)
    );

    companion object {
        fun fromRaw(raw: String): LantanaVariant =
            entries.firstOrNull { it.name == raw } ?: UNKNOWN
    }
}
