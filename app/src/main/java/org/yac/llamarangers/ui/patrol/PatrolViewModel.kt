package org.yac.llamarangers.ui.patrol

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import org.yac.llamarangers.auth.AuthManager
import org.yac.llamarangers.data.repository.PatrolRepository
import org.yac.llamarangers.domain.model.Patrol
import org.yac.llamarangers.domain.model.PatrolChecklistItem
import org.yac.llamarangers.util.PortStewartZones
import javax.inject.Inject

@HiltViewModel
class PatrolViewModel @Inject constructor(
    private val patrolRepository: PatrolRepository,
    private val authManager: AuthManager
) : ViewModel() {

    val patrolAreas = PortStewartZones.patrolAreas

    val patrols: StateFlow<List<Patrol>> = patrolRepository.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val activePatrol: StateFlow<Patrol?> = patrols.map { list ->
        list.firstOrNull { it.isActive && it.rangerId == authManager.currentRangerId.value }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    private val _selectedArea = MutableStateFlow(PortStewartZones.patrolAreas.first())
    val selectedArea: StateFlow<String> get() = _selectedArea

    private val _finishNotes = MutableStateFlow("")
    val finishNotes: StateFlow<String> get() = _finishNotes

    fun selectArea(area: String) { _selectedArea.value = area }
    fun updateFinishNotes(text: String) { _finishNotes.value = text }

    fun startPatrol() {
        val rangerId = authManager.currentRangerId.value ?: return
        viewModelScope.launch {
            patrolRepository.startPatrol(
                rangerId = rangerId,
                areaName = _selectedArea.value,
                checklistItems = PortStewartZones.defaultChecklistForArea(_selectedArea.value)
            )
        }
    }

    fun toggleItem(item: PatrolChecklistItem) {
        val patrol = activePatrol.value ?: return
        val now = System.currentTimeMillis()
        val updated = patrol.checklistItems.map {
            if (it.id == item.id)
                it.copy(isCompleted = !it.isCompleted, completedAt = if (!it.isCompleted) now else null)
            else it
        }
        viewModelScope.launch {
            patrolRepository.updateChecklist(patrol, updated)
        }
    }

    fun finishPatrol() {
        val patrol = activePatrol.value ?: return
        viewModelScope.launch {
            patrolRepository.finishPatrol(patrol, _finishNotes.value.takeIf { it.isNotBlank() })
            _finishNotes.value = ""
        }
    }
}
