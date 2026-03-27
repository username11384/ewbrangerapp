package org.yac.llamarangers.ui.navigation

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import org.yac.llamarangers.auth.AuthManager
import javax.inject.Inject

@HiltViewModel
class AuthNavViewModel @Inject constructor(
    val authManager: AuthManager
) : ViewModel()
