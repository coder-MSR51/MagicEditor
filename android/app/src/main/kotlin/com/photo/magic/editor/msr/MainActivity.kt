package com.photo.magic.editor.msr

import android.Manifest
import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.photo.magic.editor/vault"
    private val REQUEST_PICK_MEDIA = 2001
    private val REQUEST_DELETE_MEDIA = 2002
    private val REQUEST_PERMISSIONS_CODE = 2003

    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingDeleteResult: MethodChannel.Result? = null
    private var pendingPermResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAndRequestPermissions" -> {
                    checkAndRequestPermissions(result)
                }
                "pickPhotosForVault" -> {
                    if (pendingPickResult != null) {
                        result.error("BUSY", "Another pick operation is in progress", null)
                        return@setMethodCallHandler
                    }
                    pendingPickResult = result
                    launchPhotoPicker()
                }
                "deleteFromGallery" -> {
                    val uris = call.argument<List<String>>("uris") ?: emptyList()
                    val items = call.argument<List<Map<String, Any>>>("items") ?: emptyList()
                    deletePhotosFromGallery(uris, items, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAndRequestPermissions(result: MethodChannel.Result) {
        val permissionsToRequest = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_IMAGES) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.READ_MEDIA_IMAGES)
            }
        } else {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                    permissionsToRequest.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                }
            }
        }

        if (permissionsToRequest.isEmpty()) {
            result.success(true)
        } else {
            pendingPermResult = result
            ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), REQUEST_PERMISSIONS_CODE)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_PERMISSIONS_CODE) {
            val res = pendingPermResult
            pendingPermResult = null
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            res?.success(allGranted)
        }
    }

    private fun launchPhotoPicker() {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                    type = "image/*"
                    putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, 50)
                }
            } else {
                Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
                    type = "image/*"
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                }
            }
            startActivityForResult(intent, REQUEST_PICK_MEDIA)
        } catch (e: Exception) {
            try {
                val fallbackIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "image/*"
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    addCategory(Intent.CATEGORY_OPENABLE)
                }
                startActivityForResult(fallbackIntent, REQUEST_PICK_MEDIA)
            } catch (ex: Exception) {
                pendingPickResult?.error("PICK_FAILED", ex.message, null)
                pendingPickResult = null
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_PICK_MEDIA) {
            val res = pendingPickResult
            pendingPickResult = null
            if (res == null) return

            if (resultCode != Activity.RESULT_OK || data == null) {
                res.success(emptyList<Map<String, Any>>())
                return
            }

            val selectedUris = mutableListOf<Uri>()
            val clipData = data.clipData
            if (clipData != null) {
                for (i in 0 until clipData.itemCount) {
                    val itemUri = clipData.getItemAt(i).uri
                    if (itemUri != null) selectedUris.add(itemUri)
                }
            } else {
                data.data?.let { selectedUris.add(it) }
            }

            if (selectedUris.isEmpty()) {
                res.success(emptyList<Map<String, Any>>())
                return
            }

            Thread {
                val resultsList = mutableListOf<Map<String, Any>>()
                val timestamp = System.currentTimeMillis()

                for ((index, uri) in selectedUris.withIndex()) {
                    try {
                        var fileName = "photo_${timestamp}_$index.jpg"
                        var fileSize: Long = 0

                        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                            if (cursor.moveToFirst()) {
                                if (nameIndex != -1) {
                                    val n = cursor.getString(nameIndex)
                                    if (!n.isNullOrEmpty()) fileName = n
                                }
                                if (sizeIndex != -1) {
                                    fileSize = cursor.getLong(sizeIndex)
                                }
                            }
                        }

                        val tempFile = File(cacheDir, "vault_pick_${timestamp}_$index.tmp")
                        contentResolver.openInputStream(uri)?.use { input ->
                            FileOutputStream(tempFile).use { output ->
                                input.copyTo(output)
                            }
                        }

                        if (fileSize <= 0) {
                            fileSize = tempFile.length()
                        }

                        resultsList.add(
                            mapOf(
                                "uri" to uri.toString(),
                                "name" to fileName,
                                "size" to fileSize,
                                "tempPath" to tempFile.absolutePath
                            )
                        )
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }

                runOnUiThread {
                    res.success(resultsList)
                }
            }.start()
        } else if (requestCode == REQUEST_DELETE_MEDIA) {
            val res = pendingDeleteResult
            pendingDeleteResult = null
            if (res != null) {
                res.success(resultCode == Activity.RESULT_OK)
            }
        }
    }

    private fun deletePhotosFromGallery(
        uris: List<String>,
        items: List<Map<String, Any>>,
        result: MethodChannel.Result
    ) {
        Thread {
            val resolvedUris = mutableListOf<Uri>()

            // 1. Resolve every passed URI to guaranteed MediaStore external images URI
            for (uriStr in uris) {
                try {
                    val u = Uri.parse(uriStr)
                    val resolved = toMediaStoreUri(u)
                    if (resolved != null) {
                        resolvedUris.add(resolved)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            // 2. Fallback query using names and sizes from items if needed
            if (resolvedUris.isEmpty() && items.isNotEmpty()) {
                val matched = findMediaStoreUris(items)
                resolvedUris.addAll(matched)
            }

            val distinctUris = resolvedUris.distinct()

            runOnUiThread {
                if (distinctUris.isEmpty()) {
                    // Nothing found to delete
                    result.success(true)
                    return@runOnUiThread
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    try {
                        pendingDeleteResult = result
                        val pi = MediaStore.createDeleteRequest(contentResolver, distinctUris)
                        startIntentSenderForResult(
                            pi.intentSender,
                            REQUEST_DELETE_MEDIA,
                            null,
                            0,
                            0,
                            0,
                            null
                        )
                    } catch (e: Exception) {
                        e.printStackTrace()
                        pendingDeleteResult = null
                        result.success(false)
                    }
                } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
                    // Android 10
                    try {
                        var anyDeleted = false
                        for (u in distinctUris) {
                            contentResolver.delete(u, null, null)
                            anyDeleted = true
                        }
                        result.success(anyDeleted)
                    } catch (e: RecoverableSecurityException) {
                        pendingDeleteResult = result
                        startIntentSenderForResult(
                            e.userAction.actionIntent.intentSender,
                            REQUEST_DELETE_MEDIA,
                            null,
                            0,
                            0,
                            0,
                            null
                        )
                    } catch (e: Exception) {
                        result.success(false)
                    }
                } else {
                    // Android 9 and lower
                    try {
                        var anyDeleted = false
                        for (u in distinctUris) {
                            try {
                                contentResolver.query(u, arrayOf(MediaStore.Images.Media.DATA), null, null, null)?.use { c ->
                                    if (c.moveToFirst()) {
                                        val path = c.getString(0)
                                        if (!path.isNullOrEmpty()) {
                                            val f = File(path)
                                            if (f.exists()) f.delete()
                                            MediaScannerConnection.scanFile(applicationContext, arrayOf(path), null, null)
                                        }
                                    }
                                }
                            } catch (_: Exception) {}
                            contentResolver.delete(u, null, null)
                            anyDeleted = true
                        }
                        result.success(anyDeleted)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
            }
        }.start()
    }

    private fun toMediaStoreUri(uri: Uri): Uri? {
        // Direct MediaStore image URI
        if (uri.authority == "media" && uri.path?.contains("images/media") == true) {
            return uri
        }

        // Photo Picker URI: content://media/picker/0/com.android.providers.media.photopicker/media/1000000034
        val lastSeg = uri.lastPathSegment
        val numericId = lastSeg?.toLongOrNull()
        if (numericId != null) {
            val candidate = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, numericId)
            try {
                contentResolver.query(candidate, arrayOf(MediaStore.Images.Media._ID), null, null, null)?.use { c ->
                    if (c.moveToFirst()) return candidate
                }
            } catch (_: Exception) {}
        }

        // SAF document URI: content://com.android.providers.media.documents/document/image%3A12345
        if (uri.authority == "com.android.providers.media.documents") {
            try {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":")
                if (split.size >= 2) {
                    val id = split[1].toLongOrNull()
                    if (id != null) {
                        val candidate = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                        contentResolver.query(candidate, arrayOf(MediaStore.Images.Media._ID), null, null, null)?.use { c ->
                            if (c.moveToFirst()) return candidate
                        }
                    }
                }
            } catch (_: Exception) {}
        }

        // Query by display name and size
        var displayName: String? = null
        var size: Long = -1
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIdx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeIdx = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (nameIdx != -1) displayName = cursor.getString(nameIdx)
                    if (sizeIdx != -1) size = cursor.getLong(sizeIdx)
                }
            }
        } catch (_: Exception) {}

        if (!displayName.isNullOrEmpty()) {
            val selection = if (size > 0) {
                "${MediaStore.Images.Media.DISPLAY_NAME} = ? AND ${MediaStore.Images.Media.SIZE} = ?"
            } else {
                "${MediaStore.Images.Media.DISPLAY_NAME} = ?"
            }
            val selectionArgs = if (size > 0) arrayOf(displayName!!, size.toString()) else arrayOf(displayName!!)

            try {
                contentResolver.query(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    arrayOf(MediaStore.Images.Media._ID),
                    selection,
                    selectionArgs,
                    "${MediaStore.Images.Media.DATE_ADDED} DESC"
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID))
                        return ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                    }
                }
            } catch (_: Exception) {}
        }

        return null
    }

    private fun findMediaStoreUris(items: List<Map<String, Any>>): List<Uri> {
        val found = mutableListOf<Uri>()
        for (item in items) {
            val name = item["name"] as? String ?: continue
            val size = (item["size"] as? Number)?.toLong() ?: 0L
            val path = item["path"] as? String

            var uri: Uri? = null

            if (!path.isNullOrEmpty()) {
                try {
                    contentResolver.query(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        arrayOf(MediaStore.Images.Media._ID),
                        "${MediaStore.Images.Media.DATA} = ?",
                        arrayOf(path),
                        null
                    )?.use { c ->
                        if (c.moveToFirst()) {
                            val id = c.getLong(c.getColumnIndexOrThrow(MediaStore.Images.Media._ID))
                            uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                        }
                    }
                } catch (_: Exception) {}
            }

            if (uri == null) {
                try {
                    val selection = if (size > 0) {
                        "${MediaStore.Images.Media.DISPLAY_NAME} = ? AND ${MediaStore.Images.Media.SIZE} = ?"
                    } else {
                        "${MediaStore.Images.Media.DISPLAY_NAME} = ?"
                    }
                    val selectionArgs = if (size > 0) arrayOf(name, size.toString()) else arrayOf(name)

                    contentResolver.query(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        arrayOf(MediaStore.Images.Media._ID),
                        selection,
                        selectionArgs,
                        "${MediaStore.Images.Media.DATE_ADDED} DESC"
                    )?.use { c ->
                        if (c.moveToFirst()) {
                            val id = c.getLong(c.getColumnIndexOrThrow(MediaStore.Images.Media._ID))
                            uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                        }
                    }
                } catch (_: Exception) {}
            }

            if (uri != null) {
                found.add(uri)
            }
        }
        return found
    }
}
