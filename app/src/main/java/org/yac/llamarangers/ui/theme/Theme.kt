package org.yac.llamarangers.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary         = GreenPrimary,
    onPrimary       = androidx.compose.ui.graphics.Color.White,
    primaryContainer = GreenContainer,
    onPrimaryContainer = OnGreenContainer,
    secondary       = GreenLight,
    onSecondary     = androidx.compose.ui.graphics.Color.White,
)

@Composable
fun LlamaRangersTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColors,
        typography = Typography,
        content = content
    )
}
