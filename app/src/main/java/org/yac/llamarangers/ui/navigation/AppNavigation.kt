package org.yac.llamarangers.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsWalk
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Map
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.*
import androidx.navigation.compose.*
import org.yac.llamarangers.auth.AuthManager
import org.yac.llamarangers.ui.login.LoginScreen
import org.yac.llamarangers.ui.map.MapScreen
import org.yac.llamarangers.ui.patrol.PatrolScreen
import org.yac.llamarangers.ui.sighting.*
import javax.inject.Inject

private sealed class BottomTab(val route: String, val label: String, val icon: ImageVector) {
    object Sightings : BottomTab("sightings", "Sightings", Icons.Default.List)
    object Map       : BottomTab("map",       "Map",       Icons.Default.Map)
    object Patrol    : BottomTab("patrol",    "Patrol",    Icons.Default.DirectionsWalk)
}

private val tabs = listOf(BottomTab.Sightings, BottomTab.Map, BottomTab.Patrol)

@Composable
fun AppNavigation(authManager: AuthManager = hiltViewModel<AuthNavViewModel>().authManager) {
    val isAuthenticated by authManager.isAuthenticated.collectAsState()
    val navController = rememberNavController()

    LaunchedEffect(isAuthenticated) {
        if (isAuthenticated) {
            navController.navigate("main") {
                popUpTo("login") { inclusive = true }
            }
        } else {
            navController.navigate("login") {
                popUpTo(0) { inclusive = true }
            }
        }
    }

    NavHost(navController = navController, startDestination = if (isAuthenticated) "main" else "login") {
        composable("login") {
            LoginScreen()
        }
        composable("main") {
            MainScreen(authManager = authManager)
        }
    }
}

@Composable
private fun MainScreen(authManager: AuthManager) {
    val navController = rememberNavController()
    val currentBackStack by navController.currentBackStackEntryAsState()
    val currentRoute = currentBackStack?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar {
                tabs.forEach { tab ->
                    NavigationBarItem(
                        selected = currentRoute?.startsWith(tab.route) == true,
                        onClick = {
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) }
                    )
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = BottomTab.Sightings.route,
            modifier = Modifier.padding(padding)
        ) {
            composable(BottomTab.Sightings.route) {
                SightingListScreen(
                    onAddSighting = { navController.navigate("sightings/new") },
                    onSightingDetail = { id -> navController.navigate("sightings/$id") },
                    authManager = authManager
                )
            }
            composable("sightings/new") {
                LogSightingScreen(onBack = { navController.popBackStack() })
            }
            composable(
                route = "sightings/{sightingId}",
                arguments = listOf(navArgument("sightingId") { type = NavType.StringType })
            ) {
                SightingDetailScreen(onBack = { navController.popBackStack() })
            }
            composable(BottomTab.Map.route) {
                MapScreen()
            }
            composable(BottomTab.Patrol.route) {
                PatrolScreen()
            }
        }
    }
}
