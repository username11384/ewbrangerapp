package org.yac.llamarangers.domain.model

data class Patrol(
    val id: String,
    val rangerId: String,
    val rangerName: String = "",
    val areaName: String,
    val startTime: Long,
    val endTime: Long?,
    val notes: String?,
    val checklistItems: List<PatrolChecklistItem>,
    val createdAt: Long,
    val updatedAt: Long
) {
    val isActive: Boolean get() = endTime == null

    val completionPercentage: Float
        get() {
            if (checklistItems.isEmpty()) return 0f
            return checklistItems.count { it.isCompleted }.toFloat() / checklistItems.size
        }
}
