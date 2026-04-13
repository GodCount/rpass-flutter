package com.godcount.common_native_channel

import com.godcount.common_native_channel.features.CommonFeaturesInterface
import com.godcount.common_native_channel.features.InstalledApps
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** CommonNativeChannelPlugin */
class CommonNativeChannelPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var features: Array<CommonFeaturesInterface>

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "common_native_channel")
        channel.setMethodCallHandler(this)
        features = arrayOf(InstalledApps(channel, context))
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        val feature = features.find {
            it.methods.contains(call.method)
        }
        if (feature != null) {
            feature.handle(call, result)
        }else{
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
