package org.yac.llamarangers.util

import org.yac.llamarangers.domain.model.PatrolChecklistItem

object PortStewartZones {

    val areaCoordinates: Map<String, Pair<Double, Double>> = mapOf(
        "North Beach Dunes"        to (-14.677 to 143.702),
        "River Mouth Flats"        to (-14.711 to 143.722),
        "Camping Ground Perimeter" to (-14.700 to 143.699),
        "Airstrip Corridor"        to (-14.720 to 143.690),
        "Southern Scrub Belt"      to (-14.740 to 143.703),
        "Creek Line East"          to (-14.708 to 143.730),
        "Creek Line West"          to (-14.708 to 143.678),
        "Headland Track"           to (-14.688 to 143.718),
        "Mangrove Edge"            to (-14.728 to 143.712),
        "Central Clearing"         to (-14.710 to 143.700)
    )

    val patrolAreas: List<String> get() = areaCoordinates.keys.toList()

    private val defaultChecklist = listOf(
        "Check GPS is recording",
        "Photograph new infestations",
        "Record all Lantana sightings",
        "Check previous treatment sites",
        "Note regrowth on treated plants",
        "Check pesticide supply before departing"
    )

    fun defaultChecklistForArea(area: String): List<PatrolChecklistItem> =
        listOf(PatrolChecklistItem(label = "Walk full boundary of $area")) +
            defaultChecklist.map { PatrolChecklistItem(label = it) }
}
