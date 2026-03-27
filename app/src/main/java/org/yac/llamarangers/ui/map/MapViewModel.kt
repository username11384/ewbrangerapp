package org.yac.llamarangers.ui.map

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import org.yac.llamarangers.data.repository.SightingRepository
import org.yac.llamarangers.domain.model.Sighting
import javax.inject.Inject

@HiltViewModel
class MapViewModel @Inject constructor(
    repository: SightingRepository
) : ViewModel() {

    val sightings: StateFlow<List<Sighting>> = repository.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
}
