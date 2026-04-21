package com.godcount.rpass.autofill.helpers

import android.app.PendingIntent
import android.app.assist.AssistStructure
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.os.Build
import android.util.Log
import android.service.autofill.Dataset
import android.service.autofill.Field
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.Presentations
import android.view.View
import android.view.autofill.AutofillId
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillValue
import android.view.inputmethod.InlineSuggestionsRequest
import com.godcount.rpass.MainActivity

private const val TAG = "ResponseHelper"

class ResponseHelper private constructor(
    val context: Context,
    val structure: AssistStructure,
    val inlineSuggestion: InlineSuggestionsRequest?
) {

    private var unlockLabel = "Rpass with Autofill"

    val parsed = ViewStructureParser(structure)


    private fun Dataset.Builder.addValue(
        id: AutofillId,
        autofillValue: AutofillValue?
    ): Dataset.Builder {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            setField(
                id, autofillValue?.let {
                    Field.Builder()
                        .setValue(it)
                        .build()
                }
            )
        } else {
            @Suppress("DEPRECATION")
            setValue(id, autofillValue)
        }
        return this
    }

    private fun createDatasetBuilder(
        title: String?,
        subTitle: String?,
        datasetId: String?
    ): Dataset.Builder {
        val remoteViews = RemoteViewsHelper.viewsWithUser(
            context.packageName,
            title,
            subTitle
        )

        return when {
            Build.VERSION.SDK_INT > Build.VERSION_CODES.TIRAMISU -> Dataset.Builder(
                Presentations.Builder().apply {
                    setMenuPresentation(remoteViews)
                    setDialogPresentation(remoteViews)

                    if (inlineSuggestion != null) {
                        setInlinePresentation(
                            RemoteViewsHelper.createInlinePresentation(
                                context,
                                inlineSuggestion.inlinePresentationSpecs[0],
                                title ?: subTitle ?: "Fill me", datasetId ?: ""
                            )
                        )
                    }

                }.build()
            )

            else -> @Suppress("DEPRECATION") Dataset.Builder(remoteViews)
        }
    }

    private fun createIntentSender(flags: Boolean, manual: Boolean?): IntentSender {
        val metadata = parsed.toAutofillMetadata(manual)

        val intent = Intent(context, MainActivity::class.java)
        intent.action = Intent.ACTION_RUN

        // 复用存在的 MainActivity
        if (flags) {
            intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_NEW_TASK
        }

        intent.putExtra(AutofillManager.EXTRA_ASSIST_STRUCTURE, structure)

        intent.putExtra(
            AutofillMetadata.EXTRA_AUTOFILL_METADATA,
            metadata.toJsonString()
        )

        if (manual == true) {
            intent.putExtra(AutofillDataset.EXTRA_AUTOFILL_MANUAL_DATASET, true)
        }

        Log.d(TAG, "createIntentSender flags=$flags manual=$manual")
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_CANCEL_CURRENT
        ).intentSender

    }


    fun buildDatasetResponse(dataset: AutofillDataset): FillResponse? {

        if (dataset.unlock != true) {
            return buildAuthOrManualResponse(true, dataset.manual, dataset.message)
        }


        return FillResponse.Builder().apply {
            dataset.data.forEach { data ->
                val map = HashMap<AutofillId, AutofillValue>()

                val label = data[AutofillDataset.DATASET_FIELD_LABEL]
                val username = data[View.AUTOFILL_HINT_USERNAME]

                parsed.fields.forEach { field ->
                    if (data[field.key] != null) {
                        map[field.value] = AutofillValue.forText(data[field.key])
                    }
                }

                if (map.isNotEmpty()) {
                    val datasetBuilder = createDatasetBuilder(label, username, username ?: "")

                    map.forEach {
                        datasetBuilder.addValue(it.key, it.value)
                    }

                    addDataset(datasetBuilder.build())
                }
            }

            if (dataset.manual == true) {
                val datasetBuilder =
                    createDatasetBuilder(dataset.message ?: "Manual Select", null, null)

                parsed.fields.forEach { field ->
                    datasetBuilder.addValue(field.value, null)
                }

                datasetBuilder.setAuthentication(
                    createIntentSender(
                        flags = true,
                        manual = true
                    )
                )

                addDataset(datasetBuilder.build())
            }
        }.build()
    }

    private fun buildAuthOrManualResponse(
        flags: Boolean,
        manual: Boolean?,
        label: String?
    ): FillResponse {
        Log.d(TAG, "buildAuthOrManualResponse flags=$flags manual=$manual label=$label")

        val title = label ?: unlockLabel

        val sender = createIntentSender(flags, manual)

        val remoteViews = if (manual == true) RemoteViewsHelper.viewsWithUser(
            context.packageName,
            title,
            null
        ) else RemoteViewsHelper.viewsWithAuth(
            context.packageName,
            title,
            null
        )


        return FillResponse.Builder().apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                setAuthentication(
                    parsed.fields.values.toTypedArray(),
                    sender,
                    Presentations.Builder().setMenuPresentation(remoteViews).build()
                )
            } else {
                @Suppress("DEPRECATION")
                setAuthentication(
                    parsed.fields.values.toTypedArray(),
                    sender,
                    remoteViews
                )
            }

        }.build()

    }

    fun buildAuthResponse(flags: Boolean, label: String?): FillResponse {
        return buildAuthOrManualResponse(flags, null, label)
    }

    companion object {

        fun createResponseByStructure(
            context: Context,
            structure: AssistStructure,
            inlineSuggestion: InlineSuggestionsRequest?
        ): ResponseHelper {
            return ResponseHelper(
                context,
                structure,
                inlineSuggestion
            )
        }

        fun createResponse(
            context: Context,
            request: FillRequest,
        ): ResponseHelper {
            val structure = request.fillContexts.last().structure
            return ResponseHelper(
                context,
                structure,
                if (Build.VERSION.SDK_INT > Build.VERSION_CODES.R) request.inlineSuggestionsRequest else null
            )
        }

    }


}

data class AutofillDataset(
    val message: String?,
    val unlock: Boolean?,
    val manual: Boolean?,
    val data: List<HashMap<String, String>>
) {
    companion object {
        const val EXTRA_AUTOFILL_MANUAL_DATASET = "com.godcount.rpass.EXTRA_AUTOFILL_MANUAL_DATASET"


        const val DATASET_FIELD_LABEL = "label"


        fun fromJson(map: Map<String, Any?>): AutofillDataset = AutofillDataset(
            unlock = map["unlock"] as? Boolean,
            message = map["message"] as? String,
            manual = map["manual"] as? Boolean,
            data = map.parseDatasetList("data")
        )

        private fun Map<String, Any?>.parseDatasetList(key: String): List<HashMap<String, String>> {
            val list = this[key] as? List<*> ?: return emptyList()

            return list.mapNotNull { item ->
                val map = item.toStringMap()
                if (!map.isNullOrEmpty()) map else null
            }
        }

        private fun Any?.toStringMap(): HashMap<String, String>? {
            val map = this as? Map<*, *> ?: return null

            val result = HashMap<String, String>()
            map.forEach { (k, v) ->
                val key = k?.toString()?.takeIf { it.isNotBlank() } ?: return@forEach
                val value = v?.toString()?.takeIf { it.isNotBlank() } ?: return@forEach
                result[key] = value
            }

            return result.takeIf { it.isNotEmpty() }
        }

    }
}





