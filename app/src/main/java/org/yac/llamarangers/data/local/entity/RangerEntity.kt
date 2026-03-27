package org.yac.llamarangers.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import org.yac.llamarangers.domain.enums.RangerRole
import org.yac.llamarangers.domain.model.Ranger

@Entity(tableName = "rangers")
data class RangerEntity(
    @PrimaryKey val id: String,
    val displayName: String,
    val role: String,
    val createdAt: Long,
    val updatedAt: Long
) {
    fun toDomain() = Ranger(
        id = id,
        displayName = displayName,
        role = RangerRole.fromRaw(role),
        createdAt = createdAt,
        updatedAt = updatedAt
    )
}

fun Ranger.toEntity() = RangerEntity(
    id = id,
    displayName = displayName,
    role = when (role) {
        RangerRole.SENIOR_RANGER -> "seniorRanger"
        RangerRole.SUPERVISOR    -> "supervisor"
        else                     -> "ranger"
    },
    createdAt = createdAt,
    updatedAt = updatedAt
)
