package org.yac.llamarangers.ui.login

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import org.yac.llamarangers.auth.AuthManager
import org.yac.llamarangers.data.repository.RangerRepository
import org.yac.llamarangers.domain.model.Ranger
import javax.inject.Inject

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val rangerRepository: RangerRepository,
    private val authManager: AuthManager
) : ViewModel() {

    val rangers: StateFlow<List<Ranger>> = rangerRepository.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _selectedRanger = MutableStateFlow<Ranger?>(null)
    val selectedRanger: StateFlow<Ranger?> get() = _selectedRanger

    private val _enteredPin = MutableStateFlow("")
    val enteredPin: StateFlow<String> get() = _enteredPin

    private val _loginError = MutableStateFlow<String?>(null)
    val loginError: StateFlow<String?> get() = _loginError

    fun selectRanger(ranger: Ranger) {
        _selectedRanger.value = ranger
        _enteredPin.value = ""
        _loginError.value = null
    }

    fun appendDigit(digit: String) {
        if (_enteredPin.value.length >= 4) return
        _enteredPin.value += digit
        if (_enteredPin.value.length == 4) attemptLogin()
    }

    fun deleteDigit() {
        val pin = _enteredPin.value
        if (pin.isNotEmpty()) _enteredPin.value = pin.dropLast(1)
        _loginError.value = null
    }

    private fun attemptLogin() {
        val ranger = _selectedRanger.value ?: return
        val success = authManager.loginWithPin(ranger.id, _enteredPin.value)
        if (!success) {
            _loginError.value = "Incorrect PIN"
            _enteredPin.value = ""
        }
    }
}
