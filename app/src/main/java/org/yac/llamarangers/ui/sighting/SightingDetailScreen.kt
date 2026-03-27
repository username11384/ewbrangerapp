package org.yac.llamarangers.ui.sighting

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import org.yac.llamarangers.domain.model.Sighting
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SightingDetailScreen(
    onBack: () -> Unit,
    viewModel: SightingDetailViewModel = hiltViewModel()
) {
    val sighting by viewModel.sighting.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(sighting?.variant?.displayName ?: "Sighting") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        sighting?.let { s ->
            SightingDetailContent(
                sighting = s,
                photoFiles = viewModel.photoFiles(),
                modifier = Modifier.padding(padding)
            )
        } ?: Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
    }
}

@Composable
private fun SightingDetailContent(
    sighting: Sighting,
    photoFiles: List<java.io.File>,
    modifier: Modifier = Modifier
) {
    val fmt = remember { SimpleDateFormat("dd MMM yyyy, HH:mm", Locale.getDefault()) }
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Variant header
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(20.dp).background(sighting.variant.color, CircleShape))
            Spacer(Modifier.width(10.dp))
            Column {
                Text(sighting.variant.displayName, style = MaterialTheme.typography.titleLarge)
                Text("${sighting.infestationSize.displayName} (${sighting.infestationSize.areaDescription})",
                    style = MaterialTheme.typography.bodySmall)
            }
        }

        // GPS coords
        Surface(shape = RoundedCornerShape(8.dp), tonalElevation = 2.dp) {
            Column(Modifier.padding(12.dp)) {
                Text("Location", style = MaterialTheme.typography.titleMedium)
                Text("%.6f, %.6f".format(sighting.latitude, sighting.longitude),
                    fontFamily = FontFamily.Monospace,
                    style = MaterialTheme.typography.bodySmall)
                Text("±%.0f m accuracy".format(sighting.horizontalAccuracy),
                    style = MaterialTheme.typography.labelSmall)
            }
        }

        // Ranger + date
        Text("${sighting.rangerName} · ${fmt.format(Date(sighting.createdAt))}",
            style = MaterialTheme.typography.bodySmall)

        // Notes
        if (!sighting.notes.isNullOrBlank()) {
            Surface(shape = RoundedCornerShape(8.dp), tonalElevation = 2.dp) {
                Column(Modifier.padding(12.dp)) {
                    Text("Notes", style = MaterialTheme.typography.titleMedium)
                    Text(sighting.notes)
                }
            }
        }

        // Variant features
        Surface(shape = RoundedCornerShape(8.dp), tonalElevation = 2.dp) {
            Column(Modifier.padding(12.dp)) {
                Text("Identifying Features", style = MaterialTheme.typography.titleMedium)
                Text(sighting.variant.distinguishingFeatures, style = MaterialTheme.typography.bodySmall)
            }
        }

        // Photos
        if (photoFiles.isNotEmpty()) {
            Text("Photos", style = MaterialTheme.typography.titleMedium)
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(photoFiles) { file ->
                    AsyncImage(
                        model = file,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.size(120.dp)
                    )
                }
            }
        }
    }
}
