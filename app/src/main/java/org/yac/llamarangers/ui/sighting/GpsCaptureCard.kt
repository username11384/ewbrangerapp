package org.yac.llamarangers.ui.sighting

import android.location.Location
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import org.yac.llamarangers.location.AccuracyLevel

@Composable
fun GpsCaptureCard(
    location: Location?,
    accuracyLevel: AccuracyLevel,
    isCapturing: Boolean,
    onRecapture: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        tonalElevation = 2.dp,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (isCapturing) {
                CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp)
                Spacer(Modifier.width(12.dp))
                Text("Capturing GPS…")
            } else if (location != null) {
                Box(
                    Modifier
                        .size(12.dp)
                        .background(
                            when (accuracyLevel) {
                                AccuracyLevel.GOOD    -> Color(0xFF4CAF50)
                                AccuracyLevel.FAIR    -> Color(0xFFFF9800)
                                AccuracyLevel.POOR    -> Color(0xFFF44336)
                                AccuracyLevel.UNKNOWN -> Color.Gray
                            }, CircleShape
                        )
                )
                Spacer(Modifier.width(10.dp))
                Column(Modifier.weight(1f)) {
                    Text("%.6f, %.6f".format(location.latitude, location.longitude),
                        style = MaterialTheme.typography.bodySmall,
                        fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace)
                    Text("±%.0f m • %s".format(location.accuracy, accuracyLevel.name.lowercase().replaceFirstChar { it.uppercase() }),
                        style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                }
                TextButton(onClick = onRecapture) { Text("Recapture") }
            } else {
                Text("GPS not available", color = Color.Gray)
                Spacer(Modifier.weight(1f))
                TextButton(onClick = onRecapture) { Text("Capture") }
            }
        }
    }
}
