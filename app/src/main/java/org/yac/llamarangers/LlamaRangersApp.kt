package org.yac.llamarangers

import android.app.Application
import androidx.preference.PreferenceManager
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.osmdroid.config.Configuration
import org.yac.llamarangers.auth.AuthManager
import org.yac.llamarangers.data.local.dao.RangerDao
import org.yac.llamarangers.data.local.entity.RangerEntity
import java.util.UUID
import javax.inject.Inject

@HiltAndroidApp
class LlamaRangersApp : Application() {

    @Inject lateinit var rangerDao: RangerDao
    @Inject lateinit var authManager: AuthManager

    override fun onCreate() {
        super.onCreate()

        // Configure OSMdroid
        Configuration.getInstance().load(this, PreferenceManager.getDefaultSharedPreferences(this))
        Configuration.getInstance().userAgentValue = packageName
        Configuration.getInstance().tileFileSystemCacheMaxBytes = 50L * 1024 * 1024

        // Seed rangers + default PIN on first launch
        CoroutineScope(Dispatchers.IO).launch {
            if (rangerDao.getCount() == 0) {
                val now = System.currentTimeMillis()
                rangerDao.insertAll(
                    listOf(
                        RangerEntity(
                            id = UUID.randomUUID().toString(),
                            displayName = "Alice Johnson",
                            role = "seniorRanger",
                            createdAt = now,
                            updatedAt = now
                        ),
                        RangerEntity(
                            id = UUID.randomUUID().toString(),
                            displayName = "Bob Smith",
                            role = "ranger",
                            createdAt = now,
                            updatedAt = now
                        ),
                        RangerEntity(
                            id = UUID.randomUUID().toString(),
                            displayName = "Carol White",
                            role = "ranger",
                            createdAt = now,
                            updatedAt = now
                        )
                    )
                )
                authManager.setDefaultPin("1234")
            }
        }
    }
}
