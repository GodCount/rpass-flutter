package com.godcount.rpass.autofill


import android.app.Activity
import android.app.Activity.RESULT_OK
import android.app.assist.AssistStructure
import android.content.Context
import android.content.Intent
import android.os.*
import android.service.autofill.*
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT
import android.view.inputmethod.InlineSuggestionsRequest
import com.godcount.rpass.autofill.helpers.AutofillDataset
import com.godcount.rpass.autofill.helpers.AutofillMetadata
import com.godcount.rpass.autofill.helpers.ResponseHelper


data class LastResponse(val metadata: AutofillMetadata, val dataset: AutofillDataset)

class MyAutofillService : AutofillService() {


    companion object {
        var onAutofillRequest: ((metadata: AutofillMetadata) -> Unit)? = null

        private var fillCallback: FillCallback? = null
        private var assistStructure: AssistStructure? = null
        private var inlineSuggestion: InlineSuggestionsRequest? = null
        private var lastResponse: LastResponse? = null

        private fun getResponseHelper(context: Context, intent: Intent?): ResponseHelper? {
            if (assistStructure != null) return ResponseHelper.createResponseByStructure(
                context,
                assistStructure!!,
                inlineSuggestion
            )

            if (intent == null || !intent.hasExtra(AutofillManager.EXTRA_ASSIST_STRUCTURE)) {
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

            if (structure == null) return null

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


    override fun onFillRequest(
        request: FillRequest, cancellationSignal: CancellationSignal, callback: FillCallback
    ) {

        fillCallback = null
        assistStructure = null
        inlineSuggestion = null

        val responseHelper =
            ResponseHelper.createResponse(this, request)

        val metadata = responseHelper.parsed.toAutofillMetadata(false)

        println("metadata $metadata")

        if (!responseHelper.parsed.canAutofill()) return callback.onSuccess(null)

        assistStructure = responseHelper.structure
        inlineSuggestion = responseHelper.inlineSuggestion

        // 如果请求和上一次一样，则填充有一次的数据
        // 遇到一种情况，activity.finish() 后数据没有正确填充或丢失，导致有触发验证请求
        // 当使用 moveTaskToBack 后退, 可能不会弹出菜单
        if (lastResponse != null && lastResponse!!.metadata == metadata) {
            callback.onSuccess(responseHelper.buildDatasetResponse(lastResponse!!.dataset))
            lastResponse = null
        } else if (onAutofillRequest != null) {
            fillCallback = callback
            onAutofillRequest!!(metadata)
        } else {
            callback.onSuccess(responseHelper.buildAuthResponse(false, null))
        }

    }


    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        callback.onFailure("Not yet implemented")
    }
}




