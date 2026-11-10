package com.godcount.rpass

import android.app.Activity
import android.app.Activity.RESULT_OK
import android.content.Intent
import android.provider.Settings
import android.util.Log
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
import com.godcount.rpass.autofill.helpers.AutofillIntentMode
import com.godcount.rpass.autofill.helpers.AutofillMetadata
import com.godcount.rpass.autofill.helpers.IntentBundleKey

class NativeChannel : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener, PluginRegistry.NewIntentListener {

    companion object {
        private const val TAG = "NativeChannel"
        val REQUEST_CODE_SET_AUTOFILL_SERVICE =
            NativeChannel::class.java.hashCode() and 0xffff
    }

    private lateinit var channel: MethodChannel
    private lateinit var autofillManager: AutofillManager
    private lateinit var activityBinding: ActivityPluginBinding

    private var databaseUnlock = false
    private var lastAutofillIntent: Intent? = null
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
        channel.setMethodCallHandler(null)
        MyAutofillService.onAutofillRequest = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        lastAutofillIntent = binding.activity.intent
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
        activityBinding.removeActivityResultListener(this)
        activityBinding.removeOnNewIntentListener(this)
        lastAutofillIntent = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        Log.d(TAG, "onNewIntent action=${intent.action} extras=${intent.extras?.keySet()}")
        if (intent.hasExtra(IntentBundleKey.EXTRA_AUTOFILL_BUNDLE)) {

            val datasetId = getAutofillDatasetId(intent)
            if (datasetId != null) {
                return false
            }

            val metadata = getAutofillMetadata(intent)
            if (metadata != null && databaseUnlock && getAutofillMode(intent) == AutofillIntentMode.MANUAL) {
                requestAutofill(metadata)
            }

            lastAutofillIntent = intent
            return true
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
            "database_status" -> {
                databaseUnlock = call.arguments<Boolean?>() ?: false
            }

            "autofill_service_status" -> {
                result.success(autofillManager.hasEnabledAutofillServices())
            }

            "request_enabled_autofill_service" -> {
                requestEnabledAutofillServiceResult = result

                activityBinding.activity.startActivityForResult(
                    Intent(
                        Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE,
                        "package:${activityBinding.activity.applicationContext.packageName}".toUri()
                    ), REQUEST_CODE_SET_AUTOFILL_SERVICE
                )

            }

            "disabled_autofill_service" -> {
                autofillManager.disableAutofillServices()
                result.success(null)
            }

            "get_autofill_metadata" -> {
                if (lastAutofillIntent != null) {
                    val metadata = getAutofillMetadata(lastAutofillIntent!!)
                    return result.success(metadata?.toMap())
                }
                result.success(null)
            }

            "response_autofill_dataset" -> {
                try {
                    val dataset =
                        AutofillDataset.fromJson(call.arguments<Map<String, Any?>>() ?: emptyMap())
                    result.success(responseAutofillDataset(activityBinding.activity, dataset))
                } catch (e: Exception) {
                    result.error("unknown", e.message, e)
                } finally {
                    lastAutofillIntent = null
                }
            }

            else -> result.notImplemented()
        }
    }


    private fun responseAutofillDataset(
        activity: Activity,
        dataset: AutofillDataset
    ): Boolean {
        MyAutofillService.onAutofillResponse(
            activity,
            dataset,
            lastAutofillIntent,
        )
        return true
    }

    private fun getAutofillMode(intent: Intent): AutofillIntentMode? {
        return intent.getBundleExtra(IntentBundleKey.EXTRA_AUTOFILL_BUNDLE)
            ?.getString(IntentBundleKey.EXTRA_AUTOFILL_INTENT_MODE)
            ?.let { name -> AutofillIntentMode.entries.firstOrNull { it.name == name } }
    }

    private fun getAutofillDatasetId(intent: Intent): String? {
        return intent.getBundleExtra(IntentBundleKey.EXTRA_AUTOFILL_BUNDLE)
            ?.getString(IntentBundleKey.EXTRA_DATASET_ID)
    }

    private fun getAutofillMetadata(intent: Intent): AutofillMetadata? {
        return intent.getBundleExtra(IntentBundleKey.EXTRA_AUTOFILL_BUNDLE)?.let {
            it.getString(IntentBundleKey.EXTRA_AUTOFILL_METADATA)
                ?.let(AutofillMetadata.Companion::fromJsonString)
        }
    }

    private fun requestAutofill(metadata: AutofillMetadata) {
        channel.invokeMethod(
            "request_autofill_metadata",
            mapOf(
                "metadata" to metadata.toMap(),
            )
        )
    }


}




