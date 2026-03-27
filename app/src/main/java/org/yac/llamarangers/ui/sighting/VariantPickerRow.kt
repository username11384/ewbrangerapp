package org.yac.llamarangers.ui.sighting

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import org.yac.llamarangers.domain.enums.LantanaVariant

@Composable
fun VariantPickerRow(
    selected: LantanaVariant?,
    onSelect: (LantanaVariant) -> Unit
) {
    LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        items(LantanaVariant.entries) { variant ->
            val isSelected = selected == variant
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .clickable { onSelect(variant) }
                    .padding(4.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(width = 70.dp, height = 50.dp)
                        .background(variant.color, RoundedCornerShape(8.dp))
                        .then(
                            if (isSelected)
                                Modifier.border(2.5.dp, Color.Black, RoundedCornerShape(8.dp))
                            else
                                Modifier
                        )
                )
                Spacer(Modifier.height(4.dp))
                Text(variant.displayName, style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}
