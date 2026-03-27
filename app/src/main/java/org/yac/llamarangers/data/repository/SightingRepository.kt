package org.yac.llamarangers.data.repository

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import org.yac.llamarangers.data.local.dao.RangerDao
import org.yac.llamarangers.data.local.dao.SightingDao
import org.yac.llamarangers.data.local.entity.toEntity
import org.yac.llamarangers.domain.model.Sighting
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SightingRepository @Inject constructor(
    private val sightingDao: SightingDao,
    private val rangerDao: RangerDao
) {
    fun observeAll(): Flow<List<Sighting>> =
        combine(sightingDao.observeAll(), rangerDao.observeAll()) { sightings, rangers ->
            val rangerMap = rangers.associate { it.id to it.displayName }
            sightings.map { it.toDomain(rangerMap[it.rangerId] ?: "") }
        }

    suspend fun getAll(): List<Sighting> {
        val rangerMap = rangerDao.getAll().associate { it.id to it.displayName }
        return sightingDao.getAll().map { it.toDomain(rangerMap[it.rangerId] ?: "") }
    }

    suspend fun getById(id: String): Sighting? {
        val entity = sightingDao.getById(id) ?: return null
        val rangerName = rangerDao.getById(entity.rangerId)?.displayName ?: ""
        return entity.toDomain(rangerName)
    }

    suspend fun insert(sighting: Sighting) = sightingDao.insert(sighting.toEntity())

    suspend fun delete(sighting: Sighting) = sightingDao.delete(sighting.toEntity())

    suspend fun createSighting(
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        variant: org.yac.llamarangers.domain.enums.LantanaVariant,
        infestationSize: org.yac.llamarangers.domain.enums.InfestationSize,
        notes: String?,
        photoFilenames: List<String>,
        rangerId: String
    ): Sighting {
        val now = System.currentTimeMillis()
        val sighting = Sighting(
            id = UUID.randomUUID().toString(),
            createdAt = now,
            updatedAt = now,
            latitude = latitude,
            longitude = longitude,
            horizontalAccuracy = accuracy,
            variant = variant,
            infestationSize = infestationSize,
            notes = notes?.takeIf { it.isNotBlank() },
            photoFilenames = photoFilenames,
            rangerId = rangerId
        )
        sightingDao.insert(sighting.toEntity())
        return sighting
    }
}
