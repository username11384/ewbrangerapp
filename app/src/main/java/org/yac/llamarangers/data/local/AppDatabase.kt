package org.yac.llamarangers.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import org.yac.llamarangers.data.local.dao.PatrolDao
import org.yac.llamarangers.data.local.dao.RangerDao
import org.yac.llamarangers.data.local.dao.SightingDao
import org.yac.llamarangers.data.local.entity.PatrolEntity
import org.yac.llamarangers.data.local.entity.RangerEntity
import org.yac.llamarangers.data.local.entity.SightingEntity

@Database(
    entities = [RangerEntity::class, SightingEntity::class, PatrolEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun rangerDao(): RangerDao
    abstract fun sightingDao(): SightingDao
    abstract fun patrolDao(): PatrolDao
}
