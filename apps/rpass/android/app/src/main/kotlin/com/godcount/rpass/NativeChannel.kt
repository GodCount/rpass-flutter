package com.godcount.rpass

import android.app.Activity
import android.app.Activity.RESULT_OK
import android.app.assist.AssistStructure
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT
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
import com.godcount.rpass.autofill.helpers.DatasetStatus
import com.godcount.rpass.autofill.helpers.ResponseHelper

class NativeChannel : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener, PluginRegistry.NewIntentListener {

    companion object {
        val REQUEST_CODE_SET_AUTOFILL_SERVICE =
            NativeChannel::class.java.hashCode() and 0xffff
    }

    private var lastAutofillIntent: Intent? = null
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
            requestAutofill(it, false)
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
        lastAutofillIntent = null
        activityBinding = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        if (intent.hasExtra(AutofillMetadata.EXTRA_AUTOFILL_METADATA)) {
            if (intent.getStringExtra(AutofillDataset.EXTRA_AUTOFILL_DATASET_STATUS) == DatasetStatus.MANUAL.name) {
                val metadata = this.getAutofillMetadata(intent)

                if (metadata != null) {
                    this.requestAutofill(metadata, true);
                }

                return true;
            }
            lastAutofillIntent = intent
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

                val intent = lastAutofillIntent ?: activityBinding?.activity?.intent

                if (intent != null) {
                    val metadata = getAutofillMetadata(intent)
                    return result.success(metadata?.toMap())
                }
                result.success(null)
            }

            "response_autofill_dataset" -> {
                try {
                    if (activityBinding == null) return result.success(false)

                    val dataset =
                        AutofillDataset.fromJson(call.arguments<Map<String, Any?>>() ?: emptyMap())

                    result.success(responseAutofillDataset(activityBinding!!.activity, dataset))

                } catch (e: Exception) {
                    result.error("unknown", e.message, e)
                } finally {
                    lastAutofillIntent = null
                    if (activityBinding != null) {
                        activityBinding!!.activity.intent = Intent()
                    }
                }

            }

            else -> result.notImplemented()
        }
    }


    private fun responseAutofillDataset(
        activity: Activity,
        dataset: AutofillDataset
    ): Boolean {
        if (MyAutofillService.onAutofillResponse != null) {

            MyAutofillService.onAutofillResponse!!(
                activity,
                dataset
            )

            return true
        } else {

            val intent = lastAutofillIntent ?: activityBinding?.activity?.intent

            if (intent == null || !intent.hasExtra(AutofillManager.EXTRA_ASSIST_STRUCTURE)) {
                return false
            }

            val structure = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(
                    AutofillManager.EXTRA_ASSIST_STRUCTURE,
                    AssistStructure::class.java
                )
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(AutofillManager.EXTRA_ASSIST_STRUCTURE)
            }

            if (structure == null) return false

            MyAutofillService.activitySetResult(
                activity, ResponseHelper.createResponseByStructure(
                    activity,
                    structure,
                ), dataset, lastAutofillIntent == null
            )

            return lastAutofillIntent != null

        }
    }

    private fun getAutofillMetadata(intent: Intent): AutofillMetadata? {
        return intent.getStringExtra(
            AutofillMetadata.EXTRA_AUTOFILL_METADATA
        )?.let(AutofillMetadata.Companion::fromJsonString)
    }

    private fun requestAutofill(metadata: AutofillMetadata, manualSelect: Boolean) {
        channel?.invokeMethod(
            "request_autofill_metadata",
            mapOf(
                "metadata" to metadata.toMap(),
                "manualSelect" to manualSelect
            )
        )
    }


}




