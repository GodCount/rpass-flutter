package com.godcount.rpass.autofill


import android.app.Activity
import android.app.Activity.RESULT_OK
import android.content.Intent
import android.os.*
import android.service.autofill.*
import android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT
import com.godcount.rpass.autofill.helpers.AutofillDataset
import com.godcount.rpass.autofill.helpers.AutofillMetadata
import com.godcount.rpass.autofill.helpers.ResponseHelper


class MyAutofillService : AutofillService() {


    companion object {
        var onAutofillRequest: ((metadata: AutofillMetadata) -> Unit)? = null
        var onAutofillResponse: ((activity: Activity, dataset: List<AutofillDataset>?) -> Unit)? =
            null
    }


    override fun onFillRequest(
        request: FillRequest, cancellationSignal: CancellationSignal, callback: FillCallback
    ) {

        onAutofillResponse = null

        val helperResponse = ResponseHelper.createAuthResponse(this, request)

        if (helperResponse == null) {
            return callback.onSuccess(null)
        }

        fun setOnAutofillResponseByReply(finish: Boolean) {
            onAutofillResponse = ({ activity, dataset ->
                onAutofillResponse = null
                if (!dataset.isNullOrEmpty()) {
                    val response = ResponseHelper.createDatasetResponse(this, request, dataset)
                    val replyIntent =
                        Intent().putExtra(EXTRA_AUTHENTICATION_RESULT, response!!.response)

                    activity.setResult(RESULT_OK, replyIntent)

                    if (finish) {
                        activity.finish()
                    } else {
                        activity.moveTaskToBack(false)
                    }

                }
            })
        }


        if (onAutofillRequest != null) {
            onAutofillResponse = ({ activity, dataset ->
                onAutofillResponse = null
                if (dataset == null) {
                    setOnAutofillResponseByReply(false)
                    callback.onSuccess(helperResponse.response)
                } else if (dataset.isNotEmpty()) {
                    callback.onSuccess(
                        ResponseHelper.createDatasetResponse(
                            this,
                            request,
                            dataset
                        )?.response
                    )
                } else {
                    callback.onSuccess(null)
                }
            })
            onAutofillRequest!!(helperResponse.metadata)
        } else {
            setOnAutofillResponseByReply(true)
            callback.onSuccess(helperResponse.response)
        }

    }


    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        callback.onFailure("Not yet implemented")
    }
}




