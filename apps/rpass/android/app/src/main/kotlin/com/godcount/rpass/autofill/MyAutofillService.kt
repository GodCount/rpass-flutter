package com.godcount.rpass.autofill


import android.app.Activity
import android.app.Activity.RESULT_OK
import android.content.Intent
import android.content.pm.PackageManager
import android.os.*
import android.service.autofill.*
import android.util.Log
import android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT
import android.view.inputmethod.InlineSuggestionsRequest
import com.godcount.rpass.PreferencesHelper
import com.godcount.rpass.autofill.helpers.AutofillDataset
import com.godcount.rpass.autofill.helpers.AutofillMetadata
import com.godcount.rpass.autofill.helpers.ResponseHelper
import androidx.core.net.toUri
import com.godcount.rpass.autofill.helpers.IntentBundleKey


class HandleAutofill(
    private val request: FillRequest,
    private val callback: FillCallback,
    private val responseHelper: ResponseHelper,
    private var callbackExecuted: Boolean
) {
    companion object {
        private const val TAG = "HandleAutofill"
    }

    private var canceled = false

    private fun setFillResult(activity: Activity, response: FillResponse?, intent: Intent?) {

        if (!callbackExecuted) {
            callbackExecuted = true
            callback.onSuccess(response)
            return
        }

        if (intent != null) {
            val receiver = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(
                    IntentBundleKey.EXTRA_RESULT_RECEIVER,
                    ResultReceiver::class.java
                )
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(IntentBundleKey.EXTRA_RESULT_RECEIVER)
            }

            if (receiver != null) {
                activity.moveTaskToBack(false)
                receiver.send(RESULT_OK, Bundle().apply {
                    putParcelable(EXTRA_AUTHENTICATION_RESULT, response)
                })
                return
            }
        }

        activity.setResult(
            RESULT_OK,
            Intent().putExtra(EXTRA_AUTHENTICATION_RESULT, response)
        )
        activity.finish()
    }


    fun onAutofillResponse(activity: Activity, dataset: AutofillDataset, intent: Intent?) {
        if (canceled) return

        // 取消了
        if (dataset.unlock == true && dataset.data == null) {
            Log.w(TAG, "dataset is empty, user canceled")
            setFillResult(activity, null, intent)
            return
        }

        setFillResult(activity, responseHelper.buildDatasetResponse(dataset), intent)
    }


    fun dispose() {
        canceled = true
        if (!callbackExecuted) {
            callbackExecuted = true
            callback.onSuccess(null)
        }
    }
}


class MyAutofillService : AutofillService() {
    companion object {
        private const val TAG = "MyAutofillService"
        var onAutofillRequest: ((metadata: AutofillMetadata) -> Unit)? = null
        private var inlineSuggestionRenderServicePackageName: String? = null
        private var handleAutofill: HandleAutofill? = null

        fun onAutofillResponse(activity: Activity, dataset: AutofillDataset, intent: Intent?) {
            handleAutofill?.onAutofillResponse(activity, dataset, intent)
        }
    }


    private var appsBlacklist: Set<String>? = null
    private var domainBlacklist: Set<String>? = null
    private var debug = false

    private fun readPreferences() {
        appsBlacklist = PreferencesHelper.getAutoFillAppIdBlacklist(this)
        domainBlacklist = PreferencesHelper.getAutoFillDomainBlacklist(this)
        debug = PreferencesHelper.getAutoFillDebug(this)
    }

    override fun onCreate() {
        super.onCreate()
        readPreferences()
    }

    override fun onConnected() {
        readPreferences()
    }

    private fun checkAppsBlacklist(packageName: String?): Boolean {
        if (packageName == this.packageName) return true
        if (packageName == null || appsBlacklist.isNullOrEmpty()) return false
        return appsBlacklist!!.contains(packageName)
    }

    private fun checkDomainBlacklist(domain: String?): Boolean {
        return !(domain == null || domainBlacklist.isNullOrEmpty()) && domainBlacklist!!.any {
            domain.contains(
                it
            )
        }
    }

    private fun getInlineRendererPackage(): String? {
        if (inlineSuggestionRenderServicePackageName != null) return inlineSuggestionRenderServicePackageName
        val intent = Intent("android.service.autofill.InlineSuggestionRenderService")
        val resolveInfos = packageManager.queryIntentServices(
            intent,
            PackageManager.MATCH_SYSTEM_ONLY
        )
        inlineSuggestionRenderServicePackageName =
            resolveInfos.firstOrNull()?.serviceInfo?.packageName
        return inlineSuggestionRenderServicePackageName
    }

    private fun grantIconUriPermissions(inlineSuggestion: InlineSuggestionsRequest?) {
        for (packageName in listOfNotNull(
            "android",
            if (inlineSuggestion != null) getInlineRendererPackage() else null
        )) {
            grantUriPermission(
                packageName,
                "content://com.godcount.rpass.icon.FileProvider/icons".toUri(),
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
            )
        }
    }

    private fun clearHandleAutofill() {
        handleAutofill?.dispose()
        handleAutofill = null
    }

    override fun onFillRequest(
        request: FillRequest, cancellationSignal: CancellationSignal, callback: FillCallback
    ) {
        clearHandleAutofill()
        cancellationSignal.setOnCancelListener {
            Log.d(TAG, "cancellationSignal")
            clearHandleAutofill()
        }

        val responseHelper =
            ResponseHelper.createResponse(this, request)

        val packageName = responseHelper.parsed.packageName
            ?: responseHelper.structure.activityComponent.packageName

        Log.d(TAG, "onFillRequest packageName=$packageName request=$request")

        if (this.debug) {
            return callback.onSuccess(responseHelper.buildDebugResponse())
        }

        if (checkAppsBlacklist(packageName) || checkDomainBlacklist(responseHelper.parsed.webDomain)) {
            Log.d(TAG, "onFillRequest blocked by blacklist")
            return callback.onSuccess(null)
        }

        if (!responseHelper.parsed.canAutofill()) {
            Log.d(TAG, "onFillRequest cannot autofill")
            return callback.onSuccess(null)
        }

        grantIconUriPermissions(responseHelper.inlineSuggestion)

        if (onAutofillRequest != null) {
            Log.d(TAG, "onFillRequest dispatching onAutofillRequest")
            handleAutofill = HandleAutofill(request, callback, responseHelper, false)
            onAutofillRequest!!(responseHelper.parsed.toAutofillMetadata(null))
        } else {
            Log.d(TAG, "onFillRequest building auth response")
            handleAutofill = HandleAutofill(request, callback, responseHelper, true)
            callback.onSuccess(responseHelper.buildAuthResponse(false, null))
        }

    }


    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        callback.onFailure("Not yet implemented")
    }
}




