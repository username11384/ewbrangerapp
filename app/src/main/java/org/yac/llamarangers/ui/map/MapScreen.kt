package org.yac.llamarangers.ui.map

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MapScreen(viewModel: MapViewModel = hiltViewModel()) {
    val sightings by viewModel.sightings.collectAsState()

    Scaffold(
        topBar = { TopAppBar(title = { Text("Map") }) }
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            OsmMapView(
                sightings = sightings,
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}
