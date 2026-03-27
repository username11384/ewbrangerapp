package org.yac.llamarangers.ui.sighting

import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import org.yac.llamarangers.ui.theme.GreenPrimary

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LogSightingScreen(
    onBack: () -> Unit,
    viewModel: LogSightingViewModel = hiltViewModel()
) {
    val location     by viewModel.location.collectAsState()
    val accuracy     by viewModel.accuracyLevel.collectAsState()
    val isCapturing  by viewModel.isCapturing.collectAsState()
    val variant      by viewModel.selectedVariant.collectAsState()
    val size         by viewModel.selectedSize.collectAsState()
    val notes        by viewModel.notes.collectAsState()
    val photoFiles   by viewModel.photoFiles.collectAsState()
    val isSaving     by viewModel.isSaving.collectAsState()
    val saved        by viewModel.savedSuccessfully.collectAsState()

    val permLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { viewModel.captureLocation() }

    LaunchedEffect(saved) { if (saved) onBack() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Log Sighting") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(horizontal = 16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Spacer(Modifier.height(4.dp))

            Text("GPS Location", style = MaterialTheme.typography.titleMedium)
            GpsCaptureCard(
                location = location,
                accuracyLevel = accuracy,
                isCapturing = isCapturing,
                onRecapture = {
                    permLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
                }
            )

            Text("Lantana Variant", style = MaterialTheme.typography.titleMedium)
            VariantPickerRow(selected = variant, onSelect = viewModel::selectVariant)

            if (variant != null) {
                Surface(
                    color = MaterialTheme.colorScheme.primaryContainer,
                    shape = MaterialTheme.shapes.medium
                ) {
                    Text(
                        "Recommended: ${variant!!.controlMethods.joinToString(" or ") { it.displayName }}",
                        modifier = Modifier.padding(12.dp),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }

            Text("Infestation Size", style = MaterialTheme.typography.titleMedium)
            SizePickerRow(selected = size, onSelect = viewModel::selectSize)

            Text("Notes (optional)", style = MaterialTheme.typography.titleMedium)
            OutlinedTextField(
                value = notes,
                onValueChange = viewModel::updateNotes,
                placeholder = { Text("Describe location or observations…") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3
            )

            Text("Photos (up to 3)", style = MaterialTheme.typography.titleMedium)
            PhotoCaptureRow(
                photoFiles = photoFiles,
                onPhotoAdded = viewModel::addPhoto,
                photoFileManager = viewModel.photoFileManager
            )

            Spacer(Modifier.height(8.dp))

            Button(
                onClick = viewModel::save,
                enabled = viewModel.canSave && !isSaving,
                modifier = Modifier.fillMaxWidth().height(52.dp)
            ) {
                if (isSaving) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
                else Text("Save Sighting")
            }

            Spacer(Modifier.height(16.dp))
        }
    }
}
