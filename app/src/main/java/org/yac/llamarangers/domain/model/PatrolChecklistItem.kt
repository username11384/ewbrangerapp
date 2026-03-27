package org.yac.llamarangers.domain.model

import kotlinx.serialization.Serializable

@Serializable
data class PatrolChecklistItem(
    val id: String = java.util.UUID.randomUUID().toString(),
    val label: String,
    val isCompleted: Boolean = false,
    val completedAt: Long? = null
)
