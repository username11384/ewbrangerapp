package org.yac.llamarangers.util

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import androidx.core.content.FileProvider
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PhotoFileManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val photosDir: File
        get() = File(context.filesDir, "Photos").also { it.mkdirs() }

    fun newPhotoFile(): File = File(photosDir, "sighting_${UUID.randomUUID()}.jpg")

    fun fileForName(filename: String): File = File(photosDir, filename)

    fun uriForFile(file: File): Uri =
        FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)

    fun saveBitmap(bitmap: Bitmap, filename: String): Boolean {
        return try {
            FileOutputStream(fileForName(filename)).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
            }
            true
        } catch (e: IOException) {
            false
        }
    }
}
