package org.yac.llamarangers.ui.sighting

import android.location.Location
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import org.yac.llamarangers.auth.AuthManager
import org.yac.llamarangers.data.repository.SightingRepository
import org.yac.llamarangers.domain.enums.InfestationSize
import org.yac.llamarangers.domain.enums.LantanaVariant
import org.yac.llamarangers.location.AccuracyLevel
import org.yac.llamarangers.location.LocationManager
import org.yac.llamarangers.util.PhotoFileManager
import java.io.File
import javax.inject.Inject

@HiltViewModel
class LogSightingViewModel @Inject constructor(
    private val sightingRepository: SightingRepository,
    private val locationManager: LocationManager,
    val photoFileManager: PhotoFileManager,
    private val authManager: AuthManager
) : ViewModel() {

    private val _location      = MutableStateFlow<Location?>(null)
    val location: StateFlow<Location?> get() = _location

    private val _accuracyLevel = MutableStateFlow(AccuracyLevel.UNKNOWN)
    val accuracyLevel: StateFlow<AccuracyLevel> get() = _accuracyLevel

    private val _isCapturing   = MutableStateFlow(false)
    val isCapturing: StateFlow<Boolean> get() = _isCapturing

    private val _selectedVariant  = MutableStateFlow<LantanaVariant?>(null)
    val selectedVariant: StateFlow<LantanaVariant?> get() = _selectedVariant

    private val _selectedSize     = MutableStateFlow(InfestationSize.SMALL)
    val selectedSize: StateFlow<InfestationSize> get() = _selectedSize

    private val _notes            = MutableStateFlow("")
    val notes: StateFlow<String> get() = _notes

    private val _photoFiles       = MutableStateFlow<List<File>>(emptyList())
    val photoFiles: StateFlow<List<File>> get() = _photoFiles

    private val _isSaving         = MutableStateFlow(false)
    val isSaving: StateFlow<Boolean> get() = _isSaving

    private val _savedSuccessfully = MutableStateFlow(false)
    val savedSuccessfully: StateFlow<Boolean> get() = _savedSuccessfully

    val canSave: Boolean
        get() = _location.value != null && _selectedVariant.value != null

    init {
        captureLocation()
    }

    fun captureLocation() {
        viewModelScope.launch {
            _isCapturing.value = true
            val loc = locationManager.captureLocation()
            _location.value = loc
            _accuracyLevel.value = locationManager.accuracyLevel.value
            _isCapturing.value = false
        }
    }

    fun selectVariant(variant: LantanaVariant) { _selectedVariant.value = variant }
    fun selectSize(size: InfestationSize)       { _selectedSize.value = size }
    fun updateNotes(text: String)               { _notes.value = text }

    fun addPhoto(file: File)    { _photoFiles.value = _photoFiles.value + file }
    fun removePhoto(file: File) { _photoFiles.value = _photoFiles.value - file }

    fun save() {
        val loc      = _location.value ?: return
        val variant  = _selectedVariant.value ?: return
        val rangerId = authManager.currentRangerId.value ?: return

        viewModelScope.launch {
            _isSaving.value = true
            sightingRepository.createSighting(
                latitude       = loc.latitude,
                longitude      = loc.longitude,
                accuracy       = loc.accuracy.toDouble(),
                variant        = variant,
                infestationSize = _selectedSize.value,
                notes          = _notes.value,
                photoFilenames = _photoFiles.value.map { it.name },
                rangerId       = rangerId
            )
            _isSaving.value = false
            _savedSuccessfully.value = true
        }
    }
}
