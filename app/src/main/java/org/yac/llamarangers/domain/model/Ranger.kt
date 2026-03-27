package org.yac.llamarangers.domain.model

import org.yac.llamarangers.domain.enums.RangerRole

data class Ranger(
    val id: String,
    val displayName: String,
    val role: RangerRole,
    val createdAt: Long,
    val updatedAt: Long
)
