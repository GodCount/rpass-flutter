package com.godcount.rpass

import android.app.Activity.RESULT_OK
import android.content.Intent
import android.provider.Settings
import android.view.autofill.AutofillManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import androidx.core.net.toUri
import com.godcount.rpass.autofill.MyAutofillService
import com.godcount.rpass.autofill.helpers.AutofillDataset
import com.godcount.rpass.autofill.helpers.AutofillMetadata

class NativeChannel : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener, PluginRegistry.NewIntentListener {

    companion object {
        val REQUEST_CODE_SET_AUTOFILL_SERVICE =
            NativeChannel::class.java.hashCode() and 0xffff
    }

    private var channel: MethodChannel? = null
    private var autofillManager: AutofillManager? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var requestEnabledAutofillServiceResult: Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, "native_channel_rpass")
        channel.setMethodCallHandler(this)
        this.channel = channel
        this.autofillManager =
            binding.applicationContext.getSystemService(AutofillManager::class.java)

        MyAutofillService.onAutofillRequest = {
            requestAutofill(it)
        }

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        MyAutofillService.onAutofillRequest = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        if (intent.hasExtra(AutofillMetadata.EXTRA_NAME)) {
            val metadata = getAutofillMetadata(intent)
            if (metadata != null) {
                this.requestAutofill(metadata)
                return true
            }
        }
        return false
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_SET_AUTOFILL_SERVICE) {
            requestEnabledAutofillServiceResult?.let { result ->
                requestEnabledAutofillServiceResult = null
                result.success(resultCode == RESULT_OK)
            }
            return true
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "autofill_service_status" -> {
                result.success(autofillManager?.hasEnabledAutofillServices())
            }

            "request_enabled_autofill_service" -> {
                activityBinding?.activity?.let { activity ->
                    requestEnabledAutofillServiceResult = result
                    Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE).apply {
                        data = "package:${activity.applicationContext.packageName}".toUri()
                        activity.startActivityForResult(this, REQUEST_CODE_SET_AUTOFILL_SERVICE)
                    }
                } ?: result.success(null)

            }

            "disabled_autofill_service" -> {
                autofillManager?.disableAutofillServices()
                result.success(null)
            }

            "get_autofill_metadata" -> {
                result.success(activityBinding?.activity?.intent?.let {
                    getAutofillMetadata(it)?.toMap()
                })
            }

            "response_autofill_dataset" -> {
                try {
                    if (activityBinding != null && MyAutofillService.onAutofillResponse != null) {
                        val dataset = call.argument<List<Map<String, String>>?>("dataset")
                        if (dataset == null) {
                            MyAutofillService.onAutofillResponse!!(
                                activityBinding!!.activity,
                                null
                            )
                        } else {
                            dataset.takeIf { it.isNotEmpty() }
                                ?.map { AutofillDataset.fromJson(it) }
                                ?.filter { it.username != null || it.password != null || it.otp != null }
                                ?.let {
                                    MyAutofillService.onAutofillResponse!!(
                                        activityBinding!!.activity,
                                        it
                                    )
                                }
                        }

                        result.success(true)
                    } else {
                        result.success(false)
                    }

                } catch (e: Exception) {
                    result.error("unknown", e.message, e)
                }

            }

            else -> result.notImplemented()
        }
    }

    private fun getAutofillMetadata(intent: Intent): AutofillMetadata? {
        return intent.getStringExtra(
            AutofillMetadata.EXTRA_NAME
        )?.let(AutofillMetadata.Companion::fromJsonString)
    }

    private fun requestAutofill(metadata: AutofillMetadata) {
        channel?.invokeMethod(
            "request_autofill_metadata",
            mapOf(
                "metadata" to metadata.toMap()
            )
        )
    }


}




