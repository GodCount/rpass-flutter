package com.godcount.common_native_channel.features

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build.VERSION.SDK_INT
import android.os.Build.VERSION_CODES.P
import android.util.Log
import androidx.core.graphics.createBitmap
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.security.MessageDigest

class InstalledApps(
    override val channel: MethodChannel,
    val context: Context
) : CommonFeaturesInterface {

    override val methods: Array<String> = arrayOf("get_installed_apps", "get_app_info", "start_app")

    private val scope = MainScope()

    override fun handle(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "get_installed_apps" -> {
                val force = call.argument<Boolean>("force") ?: false
                scope.launch {
                    result.success(withContext(Dispatchers.IO) {
                        Util.convertApps(
                            context,
                            force
                        )
                    })
                }
            }

            "get_app_info" -> {
                val packageName =
                    call.argument<String>("packageName") ?: return result.success(null)

                scope.launch {
                    result.success(withContext(Dispatchers.IO) {
                        Util.convertApp(context, packageName)
                    })
                }
            }

            "start_app" -> {
                result.success(startApp(call.argument<String>("packageName")))
            }

            else -> result.notImplemented()
        }
    }


    private fun startApp(packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return false
        return try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
            context.startActivity(launchIntent)
            true
        } catch (_: Exception) {
            false
        }
    }
}


fun String.md5(): String =
    MessageDigest.getInstance("MD5")
        .digest(toByteArray())
        .joinToString("") { "%02x".format(it) }


class Util {
    companion object {


        fun convertApps(context: Context, force: Boolean): List<HashMap<String, Any?>> {
            val icon = getIconCacheDir(context.cacheDir)
            val jsonFile = icon.parentFile!!.resolve("apps.json")
            if (force) {
                val packageManager = context.packageManager
                val packageInfos = packageManager.getInstalledPackages(0)
                val data = packageInfos.mapNotNull { app -> toMap(packageManager, app, icon) }
                setCache(data, jsonFile)
                return data
            } else {
                val cache = getCache(jsonFile)
                return cache ?: convertApps(context, true)
            }
        }

        fun convertApp(
            context: Context,
            packageName: String
        ): HashMap<String, Any?>? {
            val packageManager = context.packageManager
            val packageInfo = packageManager.getPackageInfo(packageName, 0)
            return toMap(packageManager, packageInfo, getIconCacheDir(context.cacheDir))
        }

        private fun toMap(
            packageManager: PackageManager,
            packageInfo: PackageInfo,
            iconCachePath: File,
        ): HashMap<String, Any?>? {

            val app: ApplicationInfo = packageInfo.applicationInfo ?: return null
            val map = HashMap<String, Any?>()

            map["name"] = packageManager.getApplicationLabel(app)
            map["packageName"] = app.packageName
            map["isSystem"] = isSystemApp(packageManager, app.packageName)
            map["versionName"] = packageInfo.versionName
            map["versionCode"] = getVersionCode(packageInfo)
            map["installedTimestamp"] = File(app.sourceDir).lastModified()

            val icon = iconCachePath.resolve("${app.packageName}.${packageInfo.versionName}".md5())

            if (!icon.exists()) {
                val data = DrawableUtil.drawableToByteArray(app.loadIcon(packageManager))
                if (data.isNotEmpty()) {
                    icon.writeBytes(data)
                }
            }

            map["icon"] = icon.absolutePath

            return map
        }

        private fun getIconCacheDir(cacheDir: File): File {
            val icon = cacheDir.resolve("apps_info_cache").resolve("icons")
            if (!icon.exists()) {
                icon.mkdirs()
            }
            return icon
        }


        private fun toJsonArray(data: List<HashMap<String, Any?>>): JSONArray {
            val jsonArr = JSONArray()
            data.forEach { map -> jsonArr.put(toJsonObject(map)) }
            return jsonArr
        }

        private fun toJsonObject(data: HashMap<String, Any?>): JSONObject {
            val obj = JSONObject()
            data.forEach { (k, v) -> obj.put(k, v) }
            return obj
        }

        private fun setCache(data: List<HashMap<String, Any?>>, file: File) {
            try {
                val json = toJsonArray(data)
                file.writeText(json.toString())
            } catch (e: Exception) {
                Log.w("InstalledAppsPlugin", "setCache: ${e.message}")
            }
        }

        private fun getCache(file: File): List<HashMap<String, Any?>>? {
            try {
                val json = JSONArray(file.readText())
                return List(json.length()) { i ->
                    val obj = json.getJSONObject(i)
                    val map = HashMap<String, Any?>()
                    obj.keys().forEach { key ->
                        val value = obj.get(key)
                        map[key] = if (value == JSONObject.NULL) null else value
                    }
                    map
                }
            } catch (e: Exception) {
                Log.w("InstalledAppsPlugin", "getCache: ${e.message}")
                return null
            }
        }


        private fun isSystemApp(packageManager: PackageManager, packageName: String): Boolean {
            return try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            } catch (_: PackageManager.NameNotFoundException) {
                false
            }
        }


        @Suppress("DEPRECATION")
        private fun getVersionCode(packageInfo: PackageInfo): Long {
            return if (SDK_INT < P) packageInfo.versionCode.toLong()
            else packageInfo.longVersionCode
        }
    }
}

class DrawableUtil {

    companion object {
        fun drawableToByteArray(drawable: Drawable): ByteArray {
            try {
                val bitmap = drawableToBitmap(drawable)
                ByteArrayOutputStream().use { stream ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    return stream.toByteArray()
                }
            } catch (e: Exception) {
                Log.w("InstalledAppsPlugin", "drawableToByteArray: ${e.message}")
                return ByteArray(0)
            }
        }

        private fun drawableToBitmap(drawable: Drawable): Bitmap {
            if (drawable is BitmapDrawable && drawable.bitmap != null) {
                return drawable.bitmap
            }
            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1
            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1
            val bitmap = createBitmap(width, height)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            return bitmap
        }
    }
}