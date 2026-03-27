package org.yac.llamarangers.ui.sighting

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material3.*
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import org.yac.llamarangers.auth.AuthManager
import org.yac.llamarangers.domain.model.Sighting
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SightingListScreen(
    onAddSighting: () -> Unit,
    onSightingDetail: (String) -> Unit,
    authManager: AuthManager,
    viewModel: SightingListViewModel = hiltViewModel()
) {
    val sightings by viewModel.filtered.collectAsState()
    val query     by viewModel.searchQuery.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Sightings") },
                actions = {
                    IconButton(onClick = { authManager.logout() }) {
                        Icon(Icons.Default.Logout, contentDescription = "Logout")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onAddSighting) {
                Icon(Icons.Default.Add, contentDescription = "Add sighting")
            }
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            OutlinedTextField(
                value = query,
                onValueChange = viewModel::updateQuery,
                placeholder = { Text("Search variant, ranger…") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                singleLine = true
            )
            LazyColumn {
                items(sightings, key = { it.id }) { sighting ->
                    SwipeToDismissBox(
                        state = rememberSwipeToDismissBoxState(
                            confirmValueChange = { value ->
                                if (value == SwipeToDismissBoxValue.EndToStart) {
                                    viewModel.delete(sighting)
                                    true
                                } else false
                            }
                        ),
                        backgroundContent = {
                            Box(
                                Modifier
                                    .fillMaxSize()
                                    .background(MaterialTheme.colorScheme.errorContainer)
                                    .padding(end = 20.dp),
                                contentAlignment = Alignment.CenterEnd
                            ) {
                                Text("Delete", color = MaterialTheme.colorScheme.onErrorContainer)
                            }
                        }
                    ) {
                        SightingRow(sighting = sighting, onClick = { onSightingDetail(sighting.id) })
                    }
                    HorizontalDivider()
                }
            }
        }
    }
}

@Composable
private fun SightingRow(sighting: Sighting, onClick: () -> Unit) {
    val fmt = remember { SimpleDateFormat("dd MMM yyyy", Locale.getDefault()) }
    ListItem(
        leadingContent = {
            Box(
                Modifier
                    .size(12.dp)
                    .background(sighting.variant.color, CircleShape)
            )
        },
        headlineContent = { Text(sighting.variant.displayName) },
        supportingContent = {
            Text("${sighting.rangerName} · ${fmt.format(Date(sighting.createdAt))} · ${sighting.infestationSize.displayName}")
        },
        trailingContent = {
            Text(
                "%.4f, %.4f".format(sighting.latitude, sighting.longitude),
                style = MaterialTheme.typography.labelSmall,
                fontFamily = FontFamily.Monospace,
                color = Color.Gray
            )
        },
        modifier = Modifier.fillMaxWidth()
    )
}
