package org.yac.llamarangers.data.local.dao

import androidx.room.*
import kotlinx.coroutines.flow.Flow
import org.yac.llamarangers.data.local.entity.RangerEntity

@Dao
interface RangerDao {
    @Query("SELECT * FROM rangers ORDER BY displayName ASC")
    fun observeAll(): Flow<List<RangerEntity>>

    @Query("SELECT * FROM rangers ORDER BY displayName ASC")
    suspend fun getAll(): List<RangerEntity>

    @Query("SELECT COUNT(*) FROM rangers")
    suspend fun getCount(): Int

    @Query("SELECT * FROM rangers WHERE id = :id LIMIT 1")
    suspend fun getById(id: String): RangerEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(ranger: RangerEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(rangers: List<RangerEntity>)

    @Delete
    suspend fun delete(ranger: RangerEntity)
}
