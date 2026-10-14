package com.example.hon

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.hon/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveImageToGallery" -> {
                        val data = call.argument<String>("data")
                        val name = call.argument<String>("name") ?: "hon_profile.jpg"
                        if (data == null) {
                            result.error("bad_args", "missing data", null)
                            return@setMethodCallHandler
                        }
                        result.success(saveImageToGallery(this, Base64.decode(data, Base64.DEFAULT), name))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// ذخیره عکس در گالری (آلبوم Pictures).
    /// از Android 10 (Q) به بالا از MediaStore استفاده می‌شود و مجوزی
    /// لازم نیست؛ در نسخه‌های قدیمی‌تر مجوز WRITE_EXTERNAL_STORAGE
    /// (که با maxSdkVersion=28 اعلام شده) لازم است.
    private fun saveImageToGallery(context: Context, bytes: ByteArray, name: String): Boolean {
        return try {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, name)
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                }
            }
            val resolver = context.contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: return false
            val os = resolver.openOutputStream(uri) ?: return false
            os.use { it.write(bytes) }
            true
        } catch (e: Exception) {
            false
        }
    }
}
