package org.yac.llamarangers.di

import android.content.Context
import android.content.SharedPreferences
import androidx.room.Room
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import org.yac.llamarangers.data.local.AppDatabase
import org.yac.llamarangers.data.local.dao.PatrolDao
import org.yac.llamarangers.data.local.dao.RangerDao
import org.yac.llamarangers.data.local.dao.SightingDao
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext ctx: Context): AppDatabase =
        Room.databaseBuilder(ctx, AppDatabase::class.java, "llamarangers.db").build()

    @Provides @Singleton fun provideRangerDao(db: AppDatabase): RangerDao = db.rangerDao()
    @Provides @Singleton fun provideSightingDao(db: AppDatabase): SightingDao = db.sightingDao()
    @Provides @Singleton fun providePatrolDao(db: AppDatabase): PatrolDao = db.patrolDao()

    @Provides
    @Singleton
    fun provideEncryptedPrefs(@ApplicationContext ctx: Context): SharedPreferences {
        val masterKey = MasterKey.Builder(ctx)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        return EncryptedSharedPreferences.create(
            ctx,
            "llamarangers_secure_prefs",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }
}
