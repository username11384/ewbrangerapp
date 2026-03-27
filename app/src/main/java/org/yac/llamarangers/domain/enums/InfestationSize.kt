package org.yac.llamarangers.domain.enums

enum class InfestationSize(val displayName: String, val areaDescription: String) {
    SMALL("Small", "< 5 m²"),
    MEDIUM("Medium", "5–50 m²"),
    LARGE("Large", "> 50 m²");

    companion object {
        fun fromRaw(raw: String): InfestationSize =
            entries.firstOrNull { it.name == raw } ?: SMALL
    }
}
