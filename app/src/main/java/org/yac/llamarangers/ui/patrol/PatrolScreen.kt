package org.yac.llamarangers.ui.patrol

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import org.yac.llamarangers.domain.model.Patrol
import org.yac.llamarangers.domain.model.PatrolChecklistItem
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PatrolScreen(viewModel: PatrolViewModel = hiltViewModel()) {
    val activePatrol by viewModel.activePatrol.collectAsState()
    val patrols      by viewModel.patrols.collectAsState()
    val selectedArea by viewModel.selectedArea.collectAsState()
    val finishNotes  by viewModel.finishNotes.collectAsState()

    Scaffold(topBar = { TopAppBar(title = { Text("Patrol") }) }) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(horizontal = 16.dp)
                .verticalScroll(rememberScrollState())
        ) {
            if (activePatrol != null) {
                ActivePatrolSection(
                    patrol = activePatrol!!,
                    finishNotes = finishNotes,
                    onFinishNotesChange = viewModel::updateFinishNotes,
                    onToggleItem = viewModel::toggleItem,
                    onFinish = viewModel::finishPatrol
                )
            } else {
                StartPatrolSection(
                    areas = viewModel.patrolAreas,
                    selectedArea = selectedArea,
                    onAreaSelected = viewModel::selectArea,
                    onStart = viewModel::startPatrol
                )
            }

            Spacer(Modifier.height(24.dp))
            Text("Patrol History", style = MaterialTheme.typography.titleMedium)
            Spacer(Modifier.height(8.dp))

            val history = patrols.filter { !it.isActive }
            if (history.isEmpty()) {
                Text("No completed patrols yet.", color = Color.Gray)
            } else {
                history.forEach { patrol ->
                    PatrolHistoryCard(patrol)
                    Spacer(Modifier.height(8.dp))
                }
            }
            Spacer(Modifier.height(16.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun StartPatrolSection(
    areas: List<String>,
    selectedArea: String,
    onAreaSelected: (String) -> Unit,
    onStart: () -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    Spacer(Modifier.height(16.dp))
    Text("Start New Patrol", style = MaterialTheme.typography.titleMedium)
    Spacer(Modifier.height(12.dp))

    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }) {
        OutlinedTextField(
            value = selectedArea,
            onValueChange = {},
            readOnly = true,
            label = { Text("Patrol Area") },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded) },
            modifier = Modifier
                .fillMaxWidth()
                .menuAnchor()
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            areas.forEach { area ->
                DropdownMenuItem(
                    text = { Text(area) },
                    onClick = { onAreaSelected(area); expanded = false }
                )
            }
        }
    }

    Spacer(Modifier.height(16.dp))
    Button(onClick = onStart, modifier = Modifier.fillMaxWidth().height(52.dp)) {
        Text("Start Patrol")
    }
}

@Composable
private fun ActivePatrolSection(
    patrol: Patrol,
    finishNotes: String,
    onFinishNotesChange: (String) -> Unit,
    onToggleItem: (PatrolChecklistItem) -> Unit,
    onFinish: () -> Unit
) {
    val pct = patrol.completionPercentage
    Spacer(Modifier.height(16.dp))
    Text("Active Patrol", style = MaterialTheme.typography.titleMedium)
    Spacer(Modifier.height(4.dp))
    Text(patrol.areaName, style = MaterialTheme.typography.titleLarge)
    Spacer(Modifier.height(8.dp))
    LinearProgressIndicator(progress = { pct }, modifier = Modifier.fillMaxWidth())
    Text("${(pct * 100).toInt()}% complete", style = MaterialTheme.typography.labelSmall)
    Spacer(Modifier.height(12.dp))

    patrol.checklistItems.forEach { item ->
        ChecklistItemRow(
            label = item.label,
            isCompleted = item.isCompleted,
            onToggle = { onToggleItem(item) }
        )
    }

    Spacer(Modifier.height(16.dp))
    OutlinedTextField(
        value = finishNotes,
        onValueChange = onFinishNotesChange,
        placeholder = { Text("Notes (optional)") },
        modifier = Modifier.fillMaxWidth(),
        minLines = 2
    )
    Spacer(Modifier.height(12.dp))
    Button(
        onClick = onFinish,
        modifier = Modifier.fillMaxWidth().height(52.dp),
        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary)
    ) {
        Text("Finish Patrol")
    }
}

@Composable
private fun PatrolHistoryCard(patrol: Patrol) {
    val fmt = remember { SimpleDateFormat("dd MMM yyyy", Locale.getDefault()) }
    val timeFmt = remember { SimpleDateFormat("HH:mm", Locale.getDefault()) }
    val endStr = patrol.endTime?.let { timeFmt.format(Date(it)) } ?: "ongoing"
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(12.dp)) {
            Text(patrol.areaName, style = MaterialTheme.typography.titleMedium)
            Text(
                "${fmt.format(Date(patrol.startTime))}  ${timeFmt.format(Date(patrol.startTime))}-$endStr",
                style = MaterialTheme.typography.bodySmall,
                color = Color.Gray
            )
            Text(
                "${(patrol.completionPercentage * 100).toInt()}% complete - ${patrol.rangerName}",
                style = MaterialTheme.typography.labelSmall
            )
            if (!patrol.notes.isNullOrBlank()) {
                Spacer(Modifier.height(4.dp))
                Text(patrol.notes, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}
