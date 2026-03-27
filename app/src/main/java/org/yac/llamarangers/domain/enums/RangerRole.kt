package org.yac.llamarangers.domain.enums

enum class RangerRole(val displayName: String) {
    RANGER("Ranger"),
    SENIOR_RANGER("Senior Ranger"),
    SUPERVISOR("Supervisor");

    companion object {
        fun fromRaw(raw: String): RangerRole = when (raw) {
            "seniorRanger" -> SENIOR_RANGER
            "supervisor"   -> SUPERVISOR
            else           -> RANGER
        }
    }
}
