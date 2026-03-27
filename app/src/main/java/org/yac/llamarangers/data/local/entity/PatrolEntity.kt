package org.yac.llamarangers.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.yac.llamarangers.domain.model.Patrol
import org.yac.llamarangers.domain.model.PatrolChecklistItem

@Entity(tableName = "patrols")
data class PatrolEntity(
    @PrimaryKey val id: String,
    val rangerId: String,
    val areaName: String,
    val startTime: Long,
    val endTime: Long?,
    val notes: String?,
    val checklistItemsJson: String,
    val createdAt: Long,
    val updatedAt: Long
) {
    fun toDomain(rangerName: String = "") = Patrol(
        id = id,
        rangerId = rangerId,
        rangerName = rangerName,
        areaName = areaName,
        startTime = startTime,
        endTime = endTime,
        notes = notes,
        checklistItems = Json.decodeFromString(checklistItemsJson),
        createdAt = createdAt,
        updatedAt = updatedAt
    )
}

fun Patrol.toEntity() = PatrolEntity(
    id = id,
    rangerId = rangerId,
    areaName = areaName,
    startTime = startTime,
    endTime = endTime,
    notes = notes,
    checklistItemsJson = Json.encodeToString(checklistItems),
    createdAt = createdAt,
    updatedAt = updatedAt
)
