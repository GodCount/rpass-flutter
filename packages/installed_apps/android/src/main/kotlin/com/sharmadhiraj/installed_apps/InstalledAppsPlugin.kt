package com.sharmadhiraj.installed_apps

import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import com.sharmadhiraj.installed_apps.Util
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class InstalledAppsPlugin : MethodCallHandler, FlutterPlugin, ActivityAware {

    private lateinit var channel: MethodChannel
    private var context: Context? = null

    private val scope = MainScope()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "installed_apps")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        context = activityPluginBinding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        context = activityPluginBinding.activity
    }

    override fun onDetachedFromActivity() {}

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (context == null) {
            result.error("ERROR", "Context is null", null)
            return
        }
        when (call.method) {
            "getInstalledApps" -> {
                val force = call.argument<Boolean>("force") ?: false
                scope.launch {
                    result.success(withContext(Dispatchers.IO) {
                        Util.convertApps(
                            context!!,
                            force
                        )
                    })
                }
            }

            "startApp" -> {
                val packageName = call.argument<String>("packageName")
                result.success(startApp(packageName))
            }

            "getAppInfo" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName == null) return result.success(null)

                scope.launch {
                    result.success(withContext(Dispatchers.IO) {
                        Util.convertApp(context!!, packageName)
                    })
                }
            }

            else -> result.notImplemented()
        }
    }


    private fun startApp(packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return false
        return try {
            val launchIntent = context!!.packageManager.getLaunchIntentForPackage(packageName)
            context!!.startActivity(launchIntent)
            true
        } catch (e: Exception) {
            Log.w("InstalledAppsPlugin", "startApp: ${e.message}")
            false
        }
    }


}
