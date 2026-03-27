package org.yac.llamarangers.data.local.dao

import androidx.room.*
import kotlinx.coroutines.flow.Flow
import org.yac.llamarangers.data.local.entity.PatrolEntity

@Dao
interface PatrolDao {
    @Query("SELECT * FROM patrols ORDER BY startTime DESC")
    fun observeAll(): Flow<List<PatrolEntity>>

    @Query("SELECT * FROM patrols ORDER BY startTime DESC")
    suspend fun getAll(): List<PatrolEntity>

    @Query("SELECT * FROM patrols WHERE id = :id LIMIT 1")
    suspend fun getById(id: String): PatrolEntity?

    @Query("SELECT * FROM patrols WHERE rangerId = :rangerId AND endTime IS NULL LIMIT 1")
    suspend fun getActivePatrol(rangerId: String): PatrolEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(patrol: PatrolEntity)

    @Update
    suspend fun update(patrol: PatrolEntity)

    @Delete
    suspend fun delete(patrol: PatrolEntity)
}
