package org.yac.llamarangers.ui.sighting

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import org.yac.llamarangers.data.repository.SightingRepository
import org.yac.llamarangers.domain.model.Sighting
import org.yac.llamarangers.util.PhotoFileManager
import java.io.File
import javax.inject.Inject

@HiltViewModel
class SightingDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: SightingRepository,
    val photoFileManager: PhotoFileManager
) : ViewModel() {

    private val sightingId: String = checkNotNull(savedStateHandle["sightingId"])

    private val _sighting = MutableStateFlow<Sighting?>(null)
    val sighting: StateFlow<Sighting?> get() = _sighting

    init {
        viewModelScope.launch {
            _sighting.value = repository.getById(sightingId)
        }
    }

    fun photoFiles(): List<File> =
        _sighting.value?.photoFilenames?.map { photoFileManager.fileForName(it) } ?: emptyList()
}
