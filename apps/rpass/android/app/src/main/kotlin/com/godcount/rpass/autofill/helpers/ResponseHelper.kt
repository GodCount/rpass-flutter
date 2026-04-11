package com.godcount.rpass.autofill.helpers

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.app.assist.AssistStructure
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.autofill.Dataset
import android.service.autofill.Field
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.InlinePresentation
import android.service.autofill.Presentations
import android.view.autofill.AutofillId
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillValue
import android.view.inputmethod.InlineSuggestionsRequest
import androidx.autofill.inline.v1.InlineSuggestionUi
import com.godcount.rpass.MainActivity


class ResponseHelper private constructor(
    private val context: Context,
    private val structure: AssistStructure,
    private val inlineSuggestion: InlineSuggestionsRequest?
) {
    private var unlockLabel = "Rpass with Autofill"

    val parsed = ViewStructureParser(structure)

    fun buildDatasetResponse(dataset: AutofillDataset): FillResponse? {

        if (dataset.status != DatasetStatus.FILL) {
            return buildAuthResponse(dataset.status,true, dataset.message);
        }

        if (dataset.data.isEmpty()) return null


        fun createAttribution(msg: String): PendingIntent {
            val intent = Intent(context, MainActivity::class.java)
            intent.putExtra("com.godcount.rpass.OPEN_USERNAME", msg)
            return PendingIntent.getActivity(
                context,
                msg.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
        }

        return FillResponse.Builder().apply {
            dataset.data.forEach { data ->

                val map = HashMap<AutofillId, AutofillValue>()

                val label = data[AutofillDataset.DATASET_FIELD_LABEL]
                val username = data[AutofillDataset.DATASET_FIELD_USERNAME]

                parsed.fields.forEach { field ->

                    if (data[AutofillDataset.DATASET_FIELD_PASSWORD] != null && ViewStructureParser.ATTRIBUTES_PASSWORD_MATCHES.containsMatchIn(
                            field.key
                        )
                    ) {
                        map[field.value] =
                            AutofillValue.forText(data[AutofillDataset.DATASET_FIELD_PASSWORD])
                    } else if (data[AutofillDataset.DATASET_FIELD_OTP] != null && ViewStructureParser.ATTRIBUTES_OTP_MATCHES.containsMatchIn(
                            field.key
                        )
                    ) {
                        map[field.value] =
                            AutofillValue.forText(data[AutofillDataset.DATASET_FIELD_OTP])
                    } else if (data[field.key] != null) {
                        map[field.value] = AutofillValue.forText(data[field.key])
                    } else {
                        map[field.value] = AutofillValue.forText(username)
                    }
                }

                if (map.isNotEmpty()) {
                    addDataset(
                        when {
                            Build.VERSION.SDK_INT > Build.VERSION_CODES.TIRAMISU -> Dataset.Builder(
                                Presentations.Builder().apply {
                                    setMenuPresentation(
                                        RemoteViewsHelper.viewsWithUser(
                                            context.packageName,
                                            label,
                                            username
                                        )
                                    )

                                    setDialogPresentation(
                                        RemoteViewsHelper.viewsWithUser(
                                            context.packageName,
                                            label,
                                            username
                                        )
                                    )


                                    if (inlineSuggestion != null) {
                                        setInlinePresentation(
                                            InlinePresentation(
                                                @SuppressLint("RestrictedApi")
                                                InlineSuggestionUi.newContentBuilder(
                                                    createAttribution(username ?: "Fill me")
                                                )
                                                    .setTitle(
                                                        label ?: username ?: "Fill me"
                                                    )
                                                    .build().slice,
                                                inlineSuggestion.inlinePresentationSpecs[0],
                                                true
                                            )
                                        )
                                    }

                                }
                                    .build()
                            ).apply {

                                map.forEach {
                                    setField(
                                        it.key, Field.Builder().setValue(it.value)
                                            .build()
                                    )
                                }

                            }.build()

                            else -> @Suppress("DEPRECATION") Dataset.Builder(
                                RemoteViewsHelper.viewsWithUser(
                                    context.packageName,
                                    label,
                                    username
                                )
                            ).apply {
                                map.forEach {
                                    setValue(
                                        it.key, it.value
                                    )
                                }
                            }.build()
                        }
                    )
                }


            }
        }.build()
    }

    fun buildAuthResponse(status: DatasetStatus, flags: Boolean, label: String?): FillResponse? {

        val title = label ?: unlockLabel

        val intent = Intent(context, MainActivity::class.java)
        intent.action = Intent.ACTION_RUN

        if (flags) {
            intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_NEW_TASK
        }

        intent.putExtra(AutofillManager.EXTRA_ASSIST_STRUCTURE, structure)

        intent.putExtra(
            AutofillMetadata.EXTRA_AUTOFILL_METADATA,
            parsed.toAutofillMetadata().toJsonString()
        )

        intent.putExtra(AutofillDataset.EXTRA_AUTOFILL_DATASET_STATUS, status.name)

        val sender = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_CANCEL_CURRENT
        ).intentSender


        return FillResponse.Builder().apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                setAuthentication(
                    parsed.fields.values.toTypedArray(),
                    sender,
                    Presentations.Builder().setMenuPresentation(
                        RemoteViewsHelper.viewsWithAuth(
                            context.packageName,
                            title,
                            null
                        )
                    ).build()
                )
            } else {
                @Suppress("DEPRECATION")
                setAuthentication(
                    parsed.fields.values.toTypedArray(),
                    sender,
                    RemoteViewsHelper.viewsWithAuth(context.packageName, title, null)
                )
            }

        }.build()

    }

    companion object {

        fun createResponseByStructure(
            context: Context,
            structure: AssistStructure,
        ): ResponseHelper {
            return ResponseHelper(
                context,
                structure,
                null
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

enum class DatasetStatus {
    AUTH, // 需要验证
    MANUAL, // 需要手动选择
    FILL // 直接填充
}

data class AutofillDataset(
    val status: DatasetStatus,
    val message: String?,
    val data: List<HashMap<String, String>>
) {
    companion object {
        const val EXTRA_AUTOFILL_DATASET_STATUS = "com.godcount.rpass.EXTRA_AUTOFILL_DATASET_STATUS"


        const val DATASET_FIELD_LABEL = "label"
        const val DATASET_FIELD_USERNAME = "username"
        const val DATASET_FIELD_PASSWORD = "password"
        const val DATASET_FIELD_OTP = "otp"


        fun fromJson(map: Map<String, Any?>): AutofillDataset = AutofillDataset(
            status = map.parseEnum("status"),
            message = map["message"] as? String,
            data = map.parseDatasetList("data")
        )

        private fun Map<String, Any?>.parseEnum(key: String): DatasetStatus {
            return DatasetStatus.valueOf((this[key] as? String ?: "FILL").uppercase())
        }

        private fun Map<String, Any?>.parseDatasetList(key: String): List<HashMap<String, String>> {
            val list = this[key] as? List<*> ?: return emptyList()

            return list.mapNotNull { item ->
                val map = item.toStringMap()
                if (map != null && map.isNotEmpty()) map else null
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





