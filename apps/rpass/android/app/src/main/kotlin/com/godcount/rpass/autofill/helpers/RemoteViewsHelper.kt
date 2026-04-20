package com.godcount.rpass.autofill.helpers

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.autofill.InlinePresentation
import android.view.View
import android.widget.RemoteViews
import android.widget.inline.InlinePresentationSpec
import androidx.annotation.DrawableRes
import androidx.annotation.RequiresApi
import androidx.autofill.inline.v1.InlineSuggestionUi
import com.godcount.rpass.MainActivity
import com.godcount.rpass.R

object RemoteViewsHelper {

    fun viewsWithAuth(packageName: String, title: String?, subtitle: String?): RemoteViews {
        return simpleRemoteViews(packageName, R.drawable.ic_lock_black_24dp, title, subtitle)
    }

    fun viewsWithUser(packageName: String, title: String?, subtitle: String?): RemoteViews {
        return simpleRemoteViews(packageName, R.drawable.ic_person_black_24dp, title, subtitle)
    }

    @RequiresApi(Build.VERSION_CODES.R)
    fun createInlinePresentation(
        context: Context,
        inlinePresentationSpec: InlinePresentationSpec,
        title: String,
        datasetId: String
    ): InlinePresentation {
        return InlinePresentation(
            @SuppressLint("RestrictedApi")
            InlineSuggestionUi.newContentBuilder(createAttribution(context, datasetId))
                .setTitle(title)
                .build().slice,
            inlinePresentationSpec,
            true
        )
    }

    private fun createAttribution(context: Context, id: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
        intent.putExtra("com.godcount.rpass.OPEN_USERNAME", id)
        return PendingIntent.getActivity(
            context,
            id.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }

    private fun simpleRemoteViews(
        packageName: String, @DrawableRes drawableId: Int, title: String?, subtitle: String?,
    ): RemoteViews {
        val presentation = RemoteViews(
            packageName,
            R.layout.multidataset_service_list_item
        )

        val text = title ?: subtitle ?: "Fill me"
        presentation.setTextViewText(R.id.label, text)

        if (title != null && subtitle != null) {
            presentation.setTextViewText(R.id.subtitle, subtitle)
        } else {
            presentation.setViewVisibility(R.id.subtitle, View.GONE)
        }

        presentation.setImageViewResource(R.id.icon, drawableId)


        return presentation
    }

}