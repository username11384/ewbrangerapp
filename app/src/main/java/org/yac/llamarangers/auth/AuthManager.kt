package org.yac.llamarangers.auth

import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthManager @Inject constructor(
    private val prefs: SharedPreferences
) {
    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> get() = _isAuthenticated

    private val _currentRangerId = MutableStateFlow<String?>(null)
    val currentRangerId: StateFlow<String?> get() = _currentRangerId

    init {
        restoreSession()
    }

    private fun restoreSession() {
        val rangerId = prefs.getString(KEY_RANGER_ID, null)
        if (rangerId != null && prefs.contains(KEY_PIN_HASH)) {
            _currentRangerId.value = rangerId
            _isAuthenticated.value = true
        }
    }

    /** Returns true if login succeeded. First login with any PIN sets it for all. */
    fun loginWithPin(rangerId: String, pin: String): Boolean {
        val storedHash = prefs.getString(KEY_PIN_HASH, null)
        return if (storedHash == null) {
            // First launch — set PIN
            prefs.edit()
                .putString(KEY_PIN_HASH, hashPin(pin))
                .putString(KEY_RANGER_ID, rangerId)
                .apply()
            _currentRangerId.value = rangerId
            _isAuthenticated.value = true
            true
        } else {
            if (hashPin(pin) == storedHash) {
                prefs.edit().putString(KEY_RANGER_ID, rangerId).apply()
                _currentRangerId.value = rangerId
                _isAuthenticated.value = true
                true
            } else {
                false
            }
        }
    }

    fun logout() {
        prefs.edit().remove(KEY_RANGER_ID).apply()
        _currentRangerId.value = null
        _isAuthenticated.value = false
    }

    /** Called on first app launch to seed default PIN "1234" */
    fun setDefaultPin(pin: String) {
        if (!prefs.contains(KEY_PIN_HASH)) {
            prefs.edit().putString(KEY_PIN_HASH, hashPin(pin)).apply()
        }
    }

    fun hashPin(pin: String): String {
        var hash = 5381L
        for (ch in pin) {
            hash = ((hash shl 5) + hash) + ch.code.toLong()
        }
        return hash.toString()
    }

    private companion object {
        const val KEY_PIN_HASH  = "pin_hash"
        const val KEY_RANGER_ID = "ranger_id"
    }
}
