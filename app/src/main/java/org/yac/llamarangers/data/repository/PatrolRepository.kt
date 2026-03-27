package org.yac.llamarangers.data.repository

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.yac.llamarangers.data.local.dao.PatrolDao
import org.yac.llamarangers.data.local.dao.RangerDao
import org.yac.llamarangers.data.local.entity.PatrolEntity
import org.yac.llamarangers.data.local.entity.toEntity
import org.yac.llamarangers.domain.model.Patrol
import org.yac.llamarangers.domain.model.PatrolChecklistItem
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PatrolRepository @Inject constructor(
    private val patrolDao: PatrolDao,
    private val rangerDao: RangerDao
) {
    fun observeAll(): Flow<List<Patrol>> =
        combine(patrolDao.observeAll(), rangerDao.observeAll()) { patrols, rangers ->
            val rangerMap = rangers.associate { it.id to it.displayName }
            patrols.map { it.toDomain(rangerMap[it.rangerId] ?: "") }
        }

    suspend fun getActivePatrol(rangerId: String): Patrol? {
        val entity = patrolDao.getActivePatrol(rangerId) ?: return null
        val rangerName = rangerDao.getById(rangerId)?.displayName ?: ""
        return entity.toDomain(rangerName)
    }

    suspend fun startPatrol(
        rangerId: String,
        areaName: String,
        checklistItems: List<PatrolChecklistItem>
    ): Patrol {
        val now = System.currentTimeMillis()
        val patrol = Patrol(
            id = UUID.randomUUID().toString(),
            rangerId = rangerId,
            areaName = areaName,
            startTime = now,
            endTime = null,
            notes = null,
            checklistItems = checklistItems,
            createdAt = now,
            updatedAt = now
        )
        patrolDao.insert(patrol.toEntity())
        return patrol
    }

    suspend fun updateChecklist(patrol: Patrol, items: List<PatrolChecklistItem>) {
        val updated = patrol.copy(checklistItems = items, updatedAt = System.currentTimeMillis())
        patrolDao.update(updated.toEntity())
    }

    suspend fun finishPatrol(patrol: Patrol, notes: String?) {
        val now = System.currentTimeMillis()
        val finished = patrol.copy(endTime = now, notes = notes, updatedAt = now)
        patrolDao.update(finished.toEntity())
    }
}
