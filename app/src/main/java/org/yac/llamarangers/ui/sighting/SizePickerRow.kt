package org.yac.llamarangers.ui.sighting

import androidx.compose.foundation.layout.*
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import org.yac.llamarangers.domain.enums.InfestationSize

@Composable
fun SizePickerRow(
    selected: InfestationSize,
    onSelect: (InfestationSize) -> Unit
) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        InfestationSize.entries.forEach { size ->
            FilterChip(
                selected = selected == size,
                onClick = { onSelect(size) },
                label = { Text("${size.displayName} (${size.areaDescription})") }
            )
        }
    }
}
