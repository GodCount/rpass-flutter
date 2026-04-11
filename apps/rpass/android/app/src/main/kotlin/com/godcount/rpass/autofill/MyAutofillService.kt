package com.godcount.rpass.autofill


import android.app.Activity
import android.app.Activity.RESULT_OK
import android.content.Intent
import android.os.*
import android.service.autofill.*
import android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT
import com.godcount.rpass.autofill.helpers.AutofillDataset
import com.godcount.rpass.autofill.helpers.AutofillMetadata
import com.godcount.rpass.autofill.helpers.DatasetStatus
import com.godcount.rpass.autofill.helpers.ResponseHelper


data class LastResponse(val metadata: AutofillMetadata, val dataset: AutofillDataset)

class MyAutofillService : AutofillService() {


    companion object {
        var onAutofillRequest: ((metadata: AutofillMetadata) -> Unit)? = null
        var onAutofillResponse: ((activity: Activity, dataset: AutofillDataset) -> Unit)? =
            null

        private var lastResponse: LastResponse? = null


        fun activitySetResult(
            activity: Activity,
            responseHelper: ResponseHelper,
            dataset: AutofillDataset,
            finish: Boolean
        ) {
            if (dataset.status == DatasetStatus.FILL) {

                val response = responseHelper.buildDatasetResponse(dataset)

                if (response != null) {
                    lastResponse = LastResponse(responseHelper.parsed.toAutofillMetadata(), dataset)
                }

                val replyIntent = Intent().putExtra(EXTRA_AUTHENTICATION_RESULT, response)
                activity.setResult(RESULT_OK, replyIntent)

                if (finish) {
                    activity.finish()
                } else {
                    activity.moveTaskToBack(false)
                }

            }
        }
    }


    override fun onFillRequest(
        request: FillRequest, cancellationSignal: CancellationSignal, callback: FillCallback
    ) {

        onAutofillResponse = null

        val responseHelper = ResponseHelper.createResponse(this, request)
        val metadata = responseHelper.parsed.toAutofillMetadata()

        if (!responseHelper.parsed.canAutofill()) return callback.onSuccess(null)

        println("metadata $metadata")

        fun setOnAutofillResponseByReply(finish: Boolean) {
            onAutofillResponse = ({ activity, dataset ->
                onAutofillResponse = null
                lastResponse = null
                activitySetResult(activity, responseHelper, dataset, finish)
            })
        }


        if (lastResponse != null && lastResponse!!.metadata.equal(metadata)) {
            callback.onSuccess(
                responseHelper.buildDatasetResponse(lastResponse!!.dataset)
            )
            lastResponse = null
        } else if (onAutofillRequest != null) {
            onAutofillResponse = ({ _, dataset ->
                onAutofillResponse = null
                lastResponse = null

                val response = responseHelper.buildDatasetResponse(dataset)

                if (dataset.status != DatasetStatus.FILL) {
                    setOnAutofillResponseByReply(false)
                } else if (response != null) {
                    lastResponse = LastResponse(metadata, dataset)
                }

                callback.onSuccess(response)
            })
            onAutofillRequest!!(metadata)
        } else {
            setOnAutofillResponseByReply(true)
            callback.onSuccess(responseHelper.buildAuthResponse(DatasetStatus.AUTH, false, null))
        }

    }


    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        callback.onFailure("Not yet implemented")
    }
}




