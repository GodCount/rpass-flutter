package com.godcount.rpass.autofill


import android.app.Activity
import android.app.Activity.RESULT_OK
import android.app.assist.AssistStructure
import android.content.Context
import android.content.Intent
import android.os.*
import android.service.autofill.*
import android.util.Log
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT
import android.view.inputmethod.InlineSuggestionsRequest
import com.godcount.rpass.PreferencesHelper
import com.godcount.rpass.autofill.helpers.AutofillDataset
import com.godcount.rpass.autofill.helpers.AutofillMetadata
import com.godcount.rpass.autofill.helpers.ResponseHelper


data class LastResponse(val metadata: AutofillMetadata, val dataset: AutofillDataset)

class MyAutofillService : AutofillService() {
    companion object {
        private const val TAG = "MyAutofillService"
        var onAutofillRequest: ((metadata: AutofillMetadata) -> Unit)? = null

        private var fillCallback: FillCallback? = null
        private var assistStructure: AssistStructure? = null
        private var inlineSuggestion: InlineSuggestionsRequest? = null
        private var lastResponse: LastResponse? = null

        private fun getResponseHelper(context: Context, intent: Intent?): ResponseHelper? {
            Log.d(TAG, "getResponseHelper intent=$intent assistStructureCached=${assistStructure != null}")
            if (assistStructure != null) return ResponseHelper.createResponseByStructure(
                context,
                assistStructure!!,
                inlineSuggestion
            )

            if (intent == null || !intent.hasExtra(AutofillManager.EXTRA_ASSIST_STRUCTURE)) {
                Log.w(TAG, "getResponseHelper missing assist structure")
                return null
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

            if (structure == null) {
                Log.w(TAG, "getResponseHelper structure was null")
                return null
            }

            return ResponseHelper.createResponseByStructure(
                context,
                structure,
                inlineSuggestion
            )

        }

        private fun setFillResult(activity: Activity, response: FillResponse?) {
            val callback = this.fillCallback
            this.fillCallback = null

            val finish = activity.intent.action == Intent.ACTION_RUN
            Log.d(TAG, "setFillResult response=${response != null} finish=$finish callbackPresent=${callback != null}")

            if (callback != null) {
                callback.onSuccess(response)
            } else {
                val replyIntent = Intent().putExtra(EXTRA_AUTHENTICATION_RESULT, response)
                activity.setResult(RESULT_OK, replyIntent)

                if (finish) {
                    activity.finish()
                } else {
                    activity.moveTaskToBack(false)
                }
            }
        }


        fun onAutofillResponse(
            activity: Activity,
            dataset: AutofillDataset,
            intent: Intent?,
        ) {
            val responseHelper = getResponseHelper(activity, intent)

            if (responseHelper == null) {
                Log.w(TAG, "onAutofillResponse responseHelper is null")
                setFillResult(activity, null)
                return
            }

            val response = responseHelper.buildDatasetResponse(dataset)

            if (response != null && dataset.unlock == true && dataset.data.isNotEmpty()) {
                lastResponse = LastResponse(responseHelper.parsed.toAutofillMetadata(null), dataset)
            }

            setFillResult(activity, response)
        }
    }


    private var appsBlacklist: Set<String>? = null
    private var domainBlacklist: Set<String>? = null


    private fun readPreferences() {
        appsBlacklist = PreferencesHelper.getAutoFillAppIdBlacklist(this)
        domainBlacklist = PreferencesHelper.getAutoFillDomainBlacklist(this)
    }

    override fun onCreate() {
        super.onCreate()
        readPreferences()
    }

    override fun onConnected() {
        readPreferences()
    }


    private fun checkAppsBlacklist(packageName: String?): Boolean {
        if (packageName == null || appsBlacklist.isNullOrEmpty()) return false
        return packageName == this.packageName || appsBlacklist!!.contains(packageName)
    }

    private fun checkDomainBlacklist(domain: String?): Boolean {
        if (domain == null || domainBlacklist.isNullOrEmpty()) return false
        return domainBlacklist!!.any { domain.contains(it) }
    }

    override fun onFillRequest(
        request: FillRequest, cancellationSignal: CancellationSignal, callback: FillCallback
    ) {
        fillCallback = null

        val responseHelper =
            ResponseHelper.createResponse(this, request)

        val packageName = responseHelper.parsed.packageName
            ?: responseHelper.structure.activityComponent.packageName
        val metadata = responseHelper.parsed.toAutofillMetadata(false)

        Log.d(TAG, "onFillRequest packageName=$packageName metadata=$metadata")

        if (checkAppsBlacklist(packageName) || checkDomainBlacklist(responseHelper.parsed.webDomain)) {
            Log.d(TAG, "onFillRequest blocked by blacklist")
            return callback.onSuccess(null)
        }

        assistStructure = null
        inlineSuggestion = null

        if (!responseHelper.parsed.canAutofill()) {
            Log.d(TAG, "onFillRequest cannot autofill")
            return callback.onSuccess(null)
        }

        assistStructure = responseHelper.structure
        inlineSuggestion = responseHelper.inlineSuggestion

        // 如果请求和上一次一样，则填充有一次的数据
        // 遇到一种情况，activity.finish() 后数据没有正确填充或丢失，导致有触发验证请求
        // 当使用 moveTaskToBack 后退, 可能不会弹出菜单
        if (lastResponse != null && lastResponse!!.metadata == metadata) {
            Log.d(TAG, "onFillRequest using lastResponse")
            callback.onSuccess(responseHelper.buildDatasetResponse(lastResponse!!.dataset))
            lastResponse = null
        } else if (onAutofillRequest != null) {
            Log.d(TAG, "onFillRequest dispatching onAutofillRequest")
            fillCallback = callback
            onAutofillRequest!!(metadata)
        } else {
            Log.d(TAG, "onFillRequest building auth response")
            callback.onSuccess(responseHelper.buildAuthResponse(false, null))
        }

    }


    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        callback.onFailure("Not yet implemented")
    }
}




