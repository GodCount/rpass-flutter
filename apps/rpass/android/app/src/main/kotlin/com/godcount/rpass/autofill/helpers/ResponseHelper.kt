package com.godcount.rpass.autofill.helpers

import android.app.PendingIntent
import android.app.assist.AssistStructure
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.service.autofill.Dataset
import android.service.autofill.Field
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.Presentations
import android.view.View
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import android.view.inputmethod.InlineSuggestionsRequest
import android.widget.inline.InlinePresentationSpec
import androidx.annotation.RequiresApi
import androidx.core.content.FileProvider
import com.godcount.rpass.MainActivity
import com.godcount.rpass.autofill.AutofillActivity
import java.io.File
import java.security.SecureRandom

private const val TAG = "ResponseHelper"


class IntentBundleKey {
    companion object {
        const val EXTRA_AUTOFILL_METADATA = "com.godcount.rpass.AUTOFILL_METADATA"
        const val EXTRA_AUTOFILL_BUNDLE = "com.godcount.rpass.AUTOFILL_BUNDLE"
        const val EXTRA_DATASET_ID = "com.godcount.rpass.DATASET_ID"
        const val EXTRA_RESULT_RECEIVER = "com.godcount.rpass.RESULT_RECEIVER"
        const val EXTRA_AUTOFILL_INTENT_MODE = "com.godcount.rpass.AUTOFILL_INTENT_MODE"

    }
}

enum class AutofillIntentMode {
    MANUAL, // 手动选择
    AUTH, // 需要验证
    DETAILS // 查看条目详情
}


class ResponseHelper private constructor(
    val context: Context,
    val structure: AssistStructure,
    val inlineSuggestion: InlineSuggestionsRequest?
) {

    private var unlockLabel = "Rpass with Autofill"

    val parsed = ViewStructureParser(structure)

    private val secureRandom = SecureRandom()

    private fun randomRequestCode(): Int {
        return secureRandom.nextInt(Int.MAX_VALUE)
    }

    private fun Dataset.Builder.addValue(
        id: AutofillId, autofillValue: AutofillValue?
    ): Dataset.Builder {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            setField(
                id, autofillValue?.let {
                    Field.Builder().setValue(it).build()
                })
        } else {
            @Suppress("DEPRECATION") setValue(id, autofillValue)
        }
        return this
    }

    private fun toIcon(filepath: String?): Icon? {
        return filepath?.let {
            Icon.createWithContentUri(
                FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.icon.FileProvider",
                    File(filepath)
                )
            )
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun getInlinePresentationSpec(index: Int?): InlinePresentationSpec? {
        if (inlineSuggestion == null || index == null || index >= inlineSuggestion.maxSuggestionCount) return null
        return inlineSuggestion.inlinePresentationSpecs[index]
    }

    private fun getMaxSuggestionCount(): Int? {
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.R) {
            val count = inlineSuggestion?.maxSuggestionCount ?: 0
            return if (count > 0) count else null
        }
        return null
    }


    private fun createDatasetBuilder(
        title: String,
        subtitle: String?,
        icon: Icon?,
        attributionIntent: PendingIntent?,
        inlinePresentationSpecIndex: Int?
    ): Dataset.Builder {

        val remoteViews =
            RemoteViewsHelper.remoteViewItem(context.packageName, title, subtitle, icon)

        when {
            Build.VERSION.SDK_INT > Build.VERSION_CODES.TIRAMISU -> {
                return Dataset.Builder(
                    Presentations.Builder().apply {
                        val inlinePresentationSpec =
                            getInlinePresentationSpec(inlinePresentationSpecIndex)

                        if (attributionIntent != null && inlinePresentationSpec != null) {
                            val presentation = RemoteViewsHelper.createInlinePresentationWithUser(
                                context,
                                attributionIntent,
                                inlinePresentationSpec,
                                title,
                                subtitle,
                                icon
                            )

                            setInlinePresentation(presentation)
                        }
                        setMenuPresentation(remoteViews)
                        setDialogPresentation(remoteViews)
                    }.build()
                )
            }

            Build.VERSION.SDK_INT > Build.VERSION_CODES.R -> {
                @Suppress("DEPRECATION") return Dataset.Builder(remoteViews).apply {
                    val inlinePresentationSpec =
                        getInlinePresentationSpec(inlinePresentationSpecIndex)

                    if (attributionIntent != null && inlinePresentationSpec != null) {
                        val presentation = RemoteViewsHelper.createInlinePresentationWithUser(
                            context,
                            attributionIntent,
                            inlinePresentationSpec,
                            title,
                            subtitle,
                            icon,
                        )
                        setInlinePresentation(presentation)
                    }
                }
            }

            else -> {
                @Suppress("DEPRECATION") return Dataset.Builder(remoteViews)
            }
        }
    }

    private fun createPendingIntent(
        reuseActivity: Boolean,
        mode: AutofillIntentMode,
        datasetId: String?
    ): PendingIntent {
        val intent = when {
            datasetId != null -> {
                Intent(context, MainActivity::class.java).apply {
                    putExtra(IntentBundleKey.EXTRA_AUTOFILL_BUNDLE, Bundle().apply {
                        putString(IntentBundleKey.EXTRA_DATASET_ID, datasetId)
                        putString(IntentBundleKey.EXTRA_AUTOFILL_INTENT_MODE, mode.name)
                    })
                    flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_NEW_TASK
                }
            }

            reuseActivity -> {
                Intent(context, AutofillActivity::class.java).apply {
                    putExtra(IntentBundleKey.EXTRA_AUTOFILL_BUNDLE, Bundle().apply {
                        putString(
                            IntentBundleKey.EXTRA_AUTOFILL_METADATA,
                            parsed.toAutofillMetadata(mode == AutofillIntentMode.MANUAL)
                                .toJsonString()
                        )
                        putString(IntentBundleKey.EXTRA_AUTOFILL_INTENT_MODE, mode.name)
                    })
                }
            }

            else -> {
                Intent(context, MainActivity::class.java).apply {
                    putExtra(IntentBundleKey.EXTRA_AUTOFILL_BUNDLE, Bundle().apply {
                        putString(
                            IntentBundleKey.EXTRA_AUTOFILL_METADATA,
                            parsed.toAutofillMetadata(mode == AutofillIntentMode.MANUAL)
                                .toJsonString()
                        )
                        putString(IntentBundleKey.EXTRA_AUTOFILL_INTENT_MODE, mode.name)
                    })
                }
            }

        }


        return PendingIntent.getActivity(
            context,
            randomRequestCode(),
            intent,
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_CANCEL_CURRENT
        )
    }


    fun buildDatasetResponse(dataset: AutofillDataset): FillResponse? {
        if (dataset.unlock != true) {
            return buildAuthResponse(true, dataset.message)
        }

        if (dataset.manual != true && dataset.data.isNullOrEmpty()) {
            return null
        }

        return FillResponse.Builder().apply {

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                setHeader(
                    RemoteViewsHelper.remoteViewHeader(
                        context.packageName, null, null
                    )
                )
            }


            val maxSuggestionCount = getMaxSuggestionCount()
            var numberInlineSuggestions: Int? = null

            if (maxSuggestionCount != null) {
                numberInlineSuggestions = if (dataset.data != null) minOf(
                    maxSuggestionCount - 1,
                    dataset.data.size
                ) else maxSuggestionCount - 1

                // 为手动选择保留一个，如果最大只有1个那就不使用内联
                if (dataset.manual == true && dataset.data != null && dataset.data.size >= maxSuggestionCount) {
                    numberInlineSuggestions =
                        if (numberInlineSuggestions == 1) null else numberInlineSuggestions - 1
                }
            }

            if (dataset.data != null) {
                val count = numberInlineSuggestions ?: dataset.data.size

                for (i in 0 until count) {
                    val data = dataset.data[i]

                    val id = data["id"]

                    val title = data[AutofillDataset.DATASET_FIELD_LABEL] ?: "User ${i + 1}"
                    val subtitle = data[View.AUTOFILL_HINT_USERNAME]
                    val icon = data["__icon__"]

                    val attributionIntent = if (inlineSuggestion != null) createPendingIntent(
                        reuseActivity = true,
                        mode = AutofillIntentMode.DETAILS,
                        datasetId = id
                    ) else null

                    val datasetBuilder = createDatasetBuilder(
                        title,
                        subtitle,
                        toIcon(icon),
                        attributionIntent,
                        numberInlineSuggestions
                    )

                    if (numberInlineSuggestions != null) numberInlineSuggestions--

                    parsed.fields.forEach { field ->
                        datasetBuilder.addValue(
                            field.value,
                            if (data[field.key] != null) AutofillValue.forText(data[field.key]) else null
                        )
                    }
                    addDataset(datasetBuilder.build())
                }
            }

            if (dataset.manual == true) {
                val attributionIntent = createPendingIntent(
                    reuseActivity = true,
                    mode = AutofillIntentMode.MANUAL,
                    datasetId = null
                )

                val datasetBuilder = createDatasetBuilder(
                    dataset.message ?: "Manual Select",
                    null,
                    null,
                    attributionIntent,
                    numberInlineSuggestions
                )

                parsed.fields.forEach { field ->
                    datasetBuilder.addValue(field.value, null)
                }

                datasetBuilder.setAuthentication(
                    attributionIntent.intentSender
                )

                addDataset(datasetBuilder.build())
            }


        }.build()
    }

    fun buildAuthResponse(reuseActivity: Boolean, label: String?): FillResponse {
        return FillResponse.Builder().apply {
            Log.d(TAG, "buildAuthResponse reuseActivity=$reuseActivity label=$label")

            val title = label ?: unlockLabel

            val attributionIntent = createPendingIntent(
                reuseActivity,
                mode = AutofillIntentMode.AUTH,
                datasetId = null
            )
            val remoteViews = RemoteViewsHelper.remoteViewItemWithAuth(
                context.packageName, title
            )

            when {
                Build.VERSION.SDK_INT > Build.VERSION_CODES.TIRAMISU -> {
                    setAuthentication(
                        parsed.fields.values.toTypedArray(),
                        attributionIntent.intentSender,
                        Presentations.Builder().apply {
                            if (inlineSuggestion != null && inlineSuggestion.maxSuggestionCount > 0) {
                                val presentation =
                                    RemoteViewsHelper.createInlinePresentationWithAuth(
                                        context,
                                        attributionIntent,
                                        inlineSuggestion.inlinePresentationSpecs[0],
                                        title
                                    )
                                setInlinePresentation(presentation)
                            }
                            setMenuPresentation(remoteViews)
                            setDialogPresentation(remoteViews)
                        }.build()
                    )
                }

                Build.VERSION.SDK_INT > Build.VERSION_CODES.R && inlineSuggestion != null && inlineSuggestion.maxSuggestionCount > 0 -> {
                    val presentation = RemoteViewsHelper.createInlinePresentationWithAuth(
                        context,
                        attributionIntent,
                        inlineSuggestion.inlinePresentationSpecs[0],
                        title
                    )
                    @Suppress("DEPRECATION") setAuthentication(
                        parsed.fields.values.toTypedArray(),
                        attributionIntent.intentSender,
                        remoteViews,
                        presentation,
                    )
                }

                else -> {
                    @Suppress("DEPRECATION") setAuthentication(
                        parsed.fields.values.toTypedArray(),
                        attributionIntent.intentSender,
                        remoteViews
                    )
                }
            }


        }.build()
    }

    fun buildDebugResponse(): FillResponse? {
        val nodes = parsed.debugParse()

        if (nodes.all { it.value.isEmpty() }) return null

        return FillResponse.Builder().apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                setHeader(
                    RemoteViewsHelper.remoteViewHeader(
                        context.packageName, "Debug", null
                    )
                )
            }

            nodes.forEach { field ->
                if (field.value.isNotEmpty()) {
                    val remoteViews = RemoteViewsHelper.remoteViewItemWithUser(
                        context.packageName, field.value, null
                    )

                    val datasetBuilder =
                        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.TIRAMISU) Dataset.Builder(
                            Presentations.Builder().apply {
                                setMenuPresentation(remoteViews)
                            }.build()
                        )
                        else @Suppress("DEPRECATION") Dataset.Builder(remoteViews)

                    nodes.forEach {
                        datasetBuilder.addValue(it.key, null)
                    }
                    addDataset(datasetBuilder.build())
                }
            }

        }.build()
    }


    companion object {

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
    val data: List<HashMap<String, String>>?,
) {
    companion object {
        const val DATASET_FIELD_LABEL = "label"

        fun fromJson(map: Map<String, Any?>): AutofillDataset = AutofillDataset(
            unlock = map["unlock"] as? Boolean,
            message = map["message"] as? String,
            manual = map["manual"] as? Boolean,
            data = map.parseDatasetList("data"),
        )

        private fun Map<String, Any?>.parseDatasetList(key: String): List<HashMap<String, String>>? {
            val list = this[key] as? List<*> ?: return null

            return list.mapNotNull { item ->
                val map = item.toStringMap()
                if (!map.isNullOrEmpty()) map else null
            }
        }

        private fun Any?.toStringMap(): HashMap<String, String>? {
            val map = this as? Map<*, *> ?: return null

            val result = HashMap<String, String>()
            for ((k, v) in map) {
                val key = k?.toString()?.takeIf { it.isNotBlank() } ?: continue
                val value = v?.toString()?.takeIf { it.isNotBlank() } ?: continue
                result[key] = value
            }
            return result.ifEmpty { null }
        }

    }
}





