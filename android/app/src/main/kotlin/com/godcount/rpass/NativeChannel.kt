package com.godcount.rpass

import android.app.Activity
import android.app.Activity.RESULT_OK
import android.app.assist.AssistStructure
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.service.autofill.Dataset
import android.service.autofill.Field
import android.service.autofill.FillResponse
import android.service.autofill.Presentations
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT
import android.view.autofill.AutofillValue
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import androidx.core.net.toUri
import com.godcount.rpass.autofill.AutofillMetadata
import com.godcount.rpass.autofill.FieldType
import com.godcount.rpass.autofill.ParsedStructure
import com.godcount.rpass.autofill.RemoteViewsHelper

class NativeChannel : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener, PluginRegistry.NewIntentListener {

    companion object {
        val REQUEST_CODE_SET_AUTOFILL_SERVICE =
            NativeChannel::class.java.hashCode() and 0xffff
    }

    private var lastIntent: Intent? = null
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
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
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
        lastIntent = intent
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
                val metadata = activityBinding?.activity?.intent?.getStringExtra(
                    AutofillMetadata.EXTRA_NAME
                )?.let(AutofillMetadata.Companion::fromJsonString)
                result.success(metadata?.toMap())
            }

            "response_autofill_dataset" -> {
                result.success(
                    activityBinding?.activity?.let { activity ->
                        call.arguments<List<Map<String, String>>>()
                            ?.takeIf { it.isNotEmpty() }
                            ?.map { AutofillDataset.fromJson(it) }
                            ?.filter { it.username != null || it.password != null || it.otp != null }
                            ?.let { dataset ->
                                responseDataset(dataset, activity)
                            }
                    } ?: false
                )
                // 只要是响应自动填充的,无论结果如何,都应该关闭这个 activity
                activityBinding?.activity?.finish()
            }

            else -> result.notImplemented()
        }
    }


    private fun responseDataset(dataset: List<AutofillDataset>, activity: Activity): Boolean {


        val structure: AssistStructure? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                lastIntent?.getParcelableExtra(
                    AutofillManager.EXTRA_ASSIST_STRUCTURE,
                    AssistStructure::class.java
                )
                    ?: activity.intent.getParcelableExtra(
                        AutofillManager.EXTRA_ASSIST_STRUCTURE,
                        AssistStructure::class.java
                    )
            } else {
                @Suppress("DEPRECATION")
                lastIntent?.getParcelableExtra(AutofillManager.EXTRA_ASSIST_STRUCTURE)
                    ?: activity.intent.getParcelableExtra(
                        AutofillManager.EXTRA_ASSIST_STRUCTURE
                    )
            }


        if (structure == null) return false

        val parsed = ParsedStructure(structure)


        val response = FillResponse.Builder().apply {
            dataset.forEach { data ->

                addDataset(
                    when {
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> Dataset.Builder(
                            Presentations.Builder().setMenuPresentation(
                                RemoteViewsHelper.viewsWithUser(
                                    activity.applicationContext.packageName,
                                    data.label,
                                    data.username
                                )
                            ).build()
                        ).apply {
                            setId("${data.label} (${data.username})")


                            val username = if (data.username != null)
                                Field.Builder().setValue(AutofillValue.forText(data.username))
                                    .build()
                            else
                                null

                            val password = if (data.password != null)
                                Field.Builder().setValue(AutofillValue.forText(data.password))
                                    .build()
                            else
                                null

                            val otp = if (data.otp != null)
                                Field.Builder().setValue(AutofillValue.forText(data.otp))
                                    .build()
                            else
                                null

                            parsed.fields.forEach { field ->
                                if (password != null && field.type == FieldType.PASSWORD) {
                                    setField(field.autofillId, password)
                                } else if (otp != null && field.type == FieldType.OTP) {
                                    setField(field.autofillId, otp)
                                } else if (username != null && (field.type == FieldType.USERNAME || field.type == FieldType.EMAIL)) {
                                    setField(field.autofillId, username)
                                } else {
                                    println("unknown type: " + field.type)
                                }
                            }

                        }.build()

                        else -> @Suppress("DEPRECATION") Dataset.Builder(
                            RemoteViewsHelper.viewsWithUser(
                                activity.applicationContext.packageName,
                                data.label,
                                data.username
                            )
                        ).apply {
                            setId("${data.label} (${data.username})")
                            parsed.fields.forEach { field ->
                                if (data.password != null && field.type == FieldType.PASSWORD) {
                                    setValue(
                                        field.autofillId,
                                        AutofillValue.forText(data.password)
                                    )
                                } else if (data.otp != null && field.type == FieldType.OTP) {
                                    setValue(
                                        field.autofillId,
                                        AutofillValue.forText(data.otp)
                                    )
                                } else if (data.username != null && (field.type == FieldType.USERNAME || field.type == FieldType.EMAIL)) {
                                    setValue(
                                        field.autofillId,
                                        AutofillValue.forText(data.username)
                                    )
                                } else {
                                    println("unknown type: " + field.type)
                                }
                            }
                        }.build()
                    }
                )

            }
        }.build()

        val replyIntent = Intent().apply {
            putExtra(EXTRA_AUTHENTICATION_RESULT, response)
        }

        activity.setResult(RESULT_OK, replyIntent)


        return true
    }


}


data class AutofillDataset(
    val label: String?,
    val username: String?,
    val password: String?,
    val otp: String?
) {

    companion object {

        fun fromJson(obj: Map<String, String>) =
            AutofillDataset(
                label = obj["label"],
                username = obj["username"],
                password = obj["password"],
                otp = obj["otp"],
            )
    }

}




