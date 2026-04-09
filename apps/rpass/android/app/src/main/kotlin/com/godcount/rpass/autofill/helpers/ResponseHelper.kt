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

    fun buildDatasetResponse(dataset: List<AutofillDataset>?): FillResponse? {
        if (!parsed.canAutofill()) return null

        if (dataset.isNullOrEmpty()) return null

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
            dataset.forEach { data ->

                val map = HashMap<AutofillId, AutofillValue>()

                parsed.fields.forEach { field ->
                    if (data.password != null && ViewStructureParser.ATTRIBUTES_PASSWORD_MATCHES.containsMatchIn(
                            field.key
                        )
                    ) {
                        map[field.value] = AutofillValue.forText(data.password)
                    } else if (data.otp != null && ViewStructureParser.ATTRIBUTES_OTP_MATCHES.containsMatchIn(
                            field.key
                        )
                    ) {
                        map[field.value] = AutofillValue.forText(data.otp)
                    } else {
                        map[field.value] = AutofillValue.forText(data.username)
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
                                            data.label,
                                            data.username
                                        )
                                    )

                                    setDialogPresentation(
                                        RemoteViewsHelper.viewsWithUser(
                                            context.packageName,
                                            data.label,
                                            data.username
                                        )
                                    )


                                    if (inlineSuggestion != null) {
                                        setInlinePresentation(
                                            InlinePresentation(
                                                @SuppressLint("RestrictedApi")
                                                InlineSuggestionUi.newContentBuilder(
                                                    createAttribution(data.username ?: "Fill me")
                                                )
                                                    .setTitle(
                                                        data.label ?: data.username ?: "Fill me"
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
                                    data.label,
                                    data.username
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

    fun buildAuthResponse(flags: Boolean): FillResponse? {
        if (!parsed.canAutofill()) return null

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
                            unlockLabel,
                            null
                        )
                    ).build()
                )
            } else {
                @Suppress("DEPRECATION")
                setAuthentication(
                    parsed.fields.values.toTypedArray(),
                    sender,
                    RemoteViewsHelper.viewsWithAuth(context.packageName, unlockLabel, null)
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







