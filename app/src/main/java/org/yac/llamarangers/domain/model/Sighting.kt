package org.yac.llamarangers.domain.model

import org.yac.llamarangers.domain.enums.InfestationSize
import org.yac.llamarangers.domain.enums.LantanaVariant

data class Sighting(
    val id: String,
    val createdAt: Long,
    val updatedAt: Long,
    val latitude: Double,
    val longitude: Double,
    val horizontalAccuracy: Double,
    val variant: LantanaVariant,
    val infestationSize: InfestationSize,
    val notes: String?,
    val photoFilenames: List<String>,
    val rangerId: String,
    val rangerName: String = ""
)
