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


data class LastResponse(val metadata: AutofillMetadata, val dataset: List<AutofillDataset>)

class MyAutofillService : AutofillService() {


    companion object {
        var onAutofillRequest: ((metadata: AutofillMetadata) -> Unit)? = null
        var onAutofillResponse: ((activity: Activity, dataset: List<AutofillDataset>?) -> Unit)? =
            null

        private var lastResponse: LastResponse? = null
    }


    override fun onFillRequest(
        request: FillRequest, cancellationSignal: CancellationSignal, callback: FillCallback
    ) {

        onAutofillResponse = null

        val responseHelper = ResponseHelper.createResponse(this, request)
        val metadata = responseHelper.parsed.toAutofillMetadata()

        println("metadata $metadata")

        fun setOnAutofillResponseByReply(finish: Boolean) {

            onAutofillResponse = ({ activity, dataset ->
                onAutofillResponse = null
                lastResponse = null
                if (!dataset.isNullOrEmpty()) {

                    val response = responseHelper.buildDatasetResponse(dataset)

                    if (response != null) {
                        lastResponse = LastResponse(metadata, dataset)
                    }

                    val replyIntent = Intent().putExtra(EXTRA_AUTHENTICATION_RESULT, response)
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
            onAutofillResponse = ({ _, dataset ->
                onAutofillResponse = null
                lastResponse = null

                if (dataset == null) {
                    setOnAutofillResponseByReply(false)
                    callback.onSuccess(responseHelper.buildAuthResponse(true))
                } else if (dataset.isNotEmpty()) {
                    val response = responseHelper.buildDatasetResponse(dataset)

                    if (response != null) {
                        lastResponse = LastResponse(metadata, dataset)
                    }

                    callback.onSuccess(response)
                } else {
                    callback.onSuccess(null)
                }
            })
            onAutofillRequest!!(metadata)
        } else if (lastResponse != null && lastResponse!!.metadata.equal(metadata)) {
            callback.onSuccess(
                responseHelper.buildDatasetResponse(lastResponse!!.dataset)
            )
            lastResponse = null
        } else {
            setOnAutofillResponseByReply(true)
            callback.onSuccess(responseHelper.buildAuthResponse(false))
        }

    }


    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        callback.onFailure("Not yet implemented")
    }
}




