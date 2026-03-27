package org.yac.llamarangers.data.repository

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.yac.llamarangers.data.local.dao.RangerDao
import org.yac.llamarangers.data.local.entity.toEntity
import org.yac.llamarangers.domain.model.Ranger
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class RangerRepository @Inject constructor(private val dao: RangerDao) {

    fun observeAll(): Flow<List<Ranger>> = dao.observeAll().map { list -> list.map { it.toDomain() } }

    suspend fun getAll(): List<Ranger> = dao.getAll().map { it.toDomain() }

    suspend fun getById(id: String): Ranger? = dao.getById(id)?.toDomain()

    suspend fun insert(ranger: Ranger) = dao.insert(ranger.toEntity())
}
