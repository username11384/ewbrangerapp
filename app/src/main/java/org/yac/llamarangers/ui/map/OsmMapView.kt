package org.yac.llamarangers.ui.map

import android.graphics.drawable.Drawable
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.graphics.drawable.DrawableCompat
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker
import org.yac.llamarangers.domain.model.Sighting

private const val PORT_STEWART_LAT = -14.7019
private const val PORT_STEWART_LON = 143.7075

@Composable
fun OsmMapView(
    sightings: List<Sighting>,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    val mapView = remember {
        MapView(context).apply {
            setTileSource(TileSourceFactory.MAPNIK)
            setMultiTouchControls(true)
            controller.setZoom(14.0)
            controller.setCenter(GeoPoint(PORT_STEWART_LAT, PORT_STEWART_LON))
        }
    }

    DisposableEffect(Unit) {
        onDispose { mapView.onDetach() }
    }

    LaunchedEffect(sightings) {
        mapView.overlays.removeAll { it is Marker }
        sightings.forEach { sighting ->
            val marker = Marker(mapView).apply {
                position = GeoPoint(sighting.latitude, sighting.longitude)
                title = "${sighting.variant.displayName} — ${sighting.infestationSize.displayName}"
                snippet = sighting.rangerName

                // Tint the default marker icon to match the variant colour
                val baseIcon: Drawable? = mapView.context.getDrawable(
                    org.osmdroid.library.R.drawable.marker_default
                )
                if (baseIcon != null) {
                    val wrapped = DrawableCompat.wrap(baseIcon.mutate())
                    DrawableCompat.setTint(wrapped, sighting.variant.color.toArgb())
                    icon = wrapped
                }
            }
            mapView.overlays.add(marker)
        }
        mapView.invalidate()
    }

    AndroidView(
        factory = { mapView },
        modifier = modifier
    ) {
        it.onResume()
    }
}
