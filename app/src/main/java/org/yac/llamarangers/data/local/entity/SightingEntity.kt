package org.yac.llamarangers.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.yac.llamarangers.domain.enums.InfestationSize
import org.yac.llamarangers.domain.enums.LantanaVariant
import org.yac.llamarangers.domain.model.Sighting

@Entity(tableName = "sightings")
data class SightingEntity(
    @PrimaryKey val id: String,
    val createdAt: Long,
    val updatedAt: Long,
    val latitude: Double,
    val longitude: Double,
    val horizontalAccuracy: Double,
    val variant: String,
    val infestationSize: String,
    val notes: String?,
    val photoFilenamesJson: String,
    val rangerId: String,
    val syncStatus: Int = 0
) {
    fun toDomain(rangerName: String = "") = Sighting(
        id = id,
        createdAt = createdAt,
        updatedAt = updatedAt,
        latitude = latitude,
        longitude = longitude,
        horizontalAccuracy = horizontalAccuracy,
        variant = LantanaVariant.fromRaw(variant),
        infestationSize = InfestationSize.fromRaw(infestationSize),
        notes = notes,
        photoFilenames = Json.decodeFromString(photoFilenamesJson),
        rangerId = rangerId,
        rangerName = rangerName
    )
}

fun Sighting.toEntity() = SightingEntity(
    id = id,
    createdAt = createdAt,
    updatedAt = updatedAt,
    latitude = latitude,
    longitude = longitude,
    horizontalAccuracy = horizontalAccuracy,
    variant = variant.name,
    infestationSize = infestationSize.name,
    notes = notes,
    photoFilenamesJson = Json.encodeToString(photoFilenames),
    rangerId = rangerId
)
