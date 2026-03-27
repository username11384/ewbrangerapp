package org.yac.llamarangers.ui.sighting

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import org.yac.llamarangers.data.repository.SightingRepository
import org.yac.llamarangers.domain.model.Sighting
import javax.inject.Inject

@HiltViewModel
class SightingListViewModel @Inject constructor(
    private val repository: SightingRepository
) : ViewModel() {

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> get() = _searchQuery

    val sightings: StateFlow<List<Sighting>> = repository.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val filtered: StateFlow<List<Sighting>> = combine(sightings, _searchQuery) { list, query ->
        if (query.isBlank()) list
        else list.filter {
            it.variant.displayName.contains(query, ignoreCase = true) ||
            it.rangerName.contains(query, ignoreCase = true) ||
            it.notes?.contains(query, ignoreCase = true) == true
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun updateQuery(q: String) { _searchQuery.value = q }

    fun delete(sighting: Sighting) {
        viewModelScope.launch { repository.delete(sighting) }
    }
}
