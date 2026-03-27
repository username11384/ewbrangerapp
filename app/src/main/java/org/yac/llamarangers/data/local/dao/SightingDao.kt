package org.yac.llamarangers.data.local.dao

import androidx.room.*
import kotlinx.coroutines.flow.Flow
import org.yac.llamarangers.data.local.entity.SightingEntity

@Dao
interface SightingDao {
    @Query("SELECT * FROM sightings ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<SightingEntity>>

    @Query("SELECT * FROM sightings ORDER BY createdAt DESC")
    suspend fun getAll(): List<SightingEntity>

    @Query("SELECT * FROM sightings WHERE id = :id LIMIT 1")
    suspend fun getById(id: String): SightingEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(sighting: SightingEntity)

    @Update
    suspend fun update(sighting: SightingEntity)

    @Delete
    suspend fun delete(sighting: SightingEntity)
}
