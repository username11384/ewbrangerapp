package org.yac.llamarangers.location

import android.annotation.SuppressLint
import android.location.Location
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume

enum class AccuracyLevel { GOOD, FAIR, POOR, UNKNOWN }

@Singleton
class LocationManager @Inject constructor(
    private val fusedClient: FusedLocationProviderClient
) {
    private val _currentLocation = MutableStateFlow<Location?>(null)
    val currentLocation: StateFlow<Location?> get() = _currentLocation

    private val _accuracyLevel = MutableStateFlow(AccuracyLevel.UNKNOWN)
    val accuracyLevel: StateFlow<AccuracyLevel> get() = _accuracyLevel

    @SuppressLint("MissingPermission")
    suspend fun captureLocation(): Location {
        val result = withTimeoutOrNull(8_000L) {
            suspendCancellableCoroutine { cont ->
                val cts = CancellationTokenSource()
                fusedClient
                    .getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, cts.token)
                    .addOnSuccessListener { loc -> cont.resume(loc) }
                    .addOnFailureListener { cont.resume(null) }
                cont.invokeOnCancellation { cts.cancel() }
            }
        }

        val location = result ?: portStewartFallback()
        _currentLocation.value = location
        _accuracyLevel.value = when {
            location.accuracy < 10f  -> AccuracyLevel.GOOD
            location.accuracy < 50f  -> AccuracyLevel.FAIR
            else                     -> AccuracyLevel.POOR
        }
        return location
    }

    private fun portStewartFallback(): Location =
        Location("fallback").also {
            it.latitude  = -14.7019
            it.longitude = 143.7075
            it.accuracy  = 50f
        }
}
