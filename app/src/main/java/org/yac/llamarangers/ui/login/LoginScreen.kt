package org.yac.llamarangers.ui.login

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import org.yac.llamarangers.ui.theme.GreenPrimary

@Composable
fun LoginScreen(viewModel: LoginViewModel = hiltViewModel()) {
    val rangers    by viewModel.rangers.collectAsState()
    val selected   by viewModel.selectedRanger.collectAsState()
    val pin        by viewModel.enteredPin.collectAsState()
    val loginError by viewModel.loginError.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .windowInsetsPadding(WindowInsets.safeDrawing)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Spacer(Modifier.height(24.dp))

        Icon(
            imageVector = Icons.Default.Eco,
            contentDescription = null,
            tint = GreenPrimary,
            modifier = Modifier.size(72.dp)
        )
        Spacer(Modifier.height(8.dp))
        Text("Lama Lama Rangers", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = GreenPrimary)
        Text("Lantana Management", fontSize = 14.sp, color = Color.Gray)

        Spacer(Modifier.height(32.dp))
        Text("Select Ranger", style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(8.dp))

        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(horizontal = 4.dp)
        ) {
            items(rangers) { ranger ->
                FilterChip(
                    selected = selected?.id == ranger.id,
                    onClick = { viewModel.selectRanger(ranger) },
                    label = { Text(ranger.displayName) }
                )
            }
        }

        Spacer(Modifier.height(24.dp))

        if (selected != null) {
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                repeat(4) { i ->
                    Box(
                        modifier = Modifier
                            .size(18.dp)
                            .then(
                                if (i < pin.length)
                                    Modifier.background(GreenPrimary, CircleShape)
                                else
                                    Modifier.border(2.dp, Color.Gray, CircleShape)
                            )
                    )
                }
            }
            Spacer(Modifier.height(8.dp))
            if (loginError != null) {
                Text(loginError!!, color = MaterialTheme.colorScheme.error, fontSize = 14.sp)
            }
            Spacer(Modifier.height(16.dp))
            PinEntryKeypad(onDigit = viewModel::appendDigit, onDelete = viewModel::deleteDigit)
        } else {
            Text("Select a ranger above to continue", color = Color.Gray, fontSize = 14.sp)
        }

        Spacer(Modifier.height(24.dp))
    }
}
