package org.yac.llamarangers

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import dagger.hilt.android.AndroidEntryPoint
import org.yac.llamarangers.ui.navigation.AppNavigation
import org.yac.llamarangers.ui.theme.LlamaRangersTheme

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            LlamaRangersTheme {
                AppNavigation()
            }
        }
    }
}
