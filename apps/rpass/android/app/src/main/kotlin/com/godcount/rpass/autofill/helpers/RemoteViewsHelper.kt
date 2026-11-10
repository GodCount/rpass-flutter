package com.godcount.rpass.autofill.helpers

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import android.service.autofill.InlinePresentation
import android.view.View
import android.widget.RemoteViews
import android.widget.inline.InlinePresentationSpec
import androidx.annotation.RequiresApi
import androidx.autofill.inline.v1.InlineSuggestionUi
import com.godcount.rpass.R

object RemoteViewsHelper {

    @SuppressLint("RestrictedApi")
    @RequiresApi(Build.VERSION_CODES.R)
    fun createInlinePresentationWithAuth(
        context: Context,
        attributionIntent: PendingIntent,
        inlinePresentationSpec: InlinePresentationSpec,
        title: String,
    ): InlinePresentation {
        return createInlinePresentation(
            attributionIntent,
            inlinePresentationSpec,
            title,
            null,
            Icon.createWithResource(context, R.drawable.ic_lock_black_24dp),
        )
    }

    @SuppressLint("RestrictedApi")
    @RequiresApi(Build.VERSION_CODES.R)
    fun createInlinePresentationWithUser(
        context: Context,
        attributionIntent: PendingIntent,
        inlinePresentationSpec: InlinePresentationSpec,
        title: String,
        subtitle: String?,
        icon: Icon?,
    ): InlinePresentation {
        return createInlinePresentation(
            attributionIntent,
            inlinePresentationSpec,
            title,
            subtitle,
            icon ?: Icon.createWithResource(context, R.drawable.ic_person_black_24dp),
        )
    }

    @SuppressLint("RestrictedApi")
    @RequiresApi(Build.VERSION_CODES.R)
    fun createInlinePresentation(
        attributionIntent: PendingIntent,
        inlinePresentationSpec: InlinePresentationSpec,
        title: String,
        subtitle: String?,
        icon: Icon?,
    ): InlinePresentation {
        return InlinePresentation(
            InlineSuggestionUi.newContentBuilder(attributionIntent).apply {
                setTitle(title)
                if (subtitle != null) {
                    setSubtitle(subtitle)
                }

                if (icon != null) {
                    setStartIcon(icon)
                }

            }.build().slice, inlinePresentationSpec, false
        )
    }


    fun remoteViewHeader(packageName: String, title: String?, bgColor: Int?): RemoteViews {
        return RemoteViews(packageName, R.layout.autofill_header).apply {
            if (!title.isNullOrEmpty()) {
                setTextViewText(R.id.autofill_title, title)
            }

            if (bgColor != null) {
                setInt(R.id.autofill_header, "setBackgroundColor", bgColor)
            }
        }
    }


    fun remoteViewItemWithAuth(packageName: String, title: String): RemoteViews {
        return remoteViewItem(
            packageName,
            title,
            null,
            Icon.createWithResource(packageName, R.drawable.ic_lock_black_24dp)
        )
    }


    fun remoteViewItemWithUser(
        packageName: String, title: String, subtitle: String?
    ): RemoteViews {
        return remoteViewItem(
            packageName,
            title,
            subtitle,
            Icon.createWithResource(packageName, R.drawable.ic_person_black_24dp)
        )
    }

    fun remoteViewItem(
        packageName: String, title: String, subtitle: String?, icon: Icon?
    ): RemoteViews {
        return RemoteViews(packageName, R.layout.autofill_item).apply {
            setTextViewText(R.id.autofill_item_title, title)

            if (subtitle != null) {
                setTextViewText(R.id.autofill_item_subtitle, subtitle)
            } else {
                setViewVisibility(R.id.autofill_item_subtitle, View.GONE)
            }


            if (icon != null) {
                setImageViewIcon(R.id.autofill_item_icon, icon)
            }

        }
    }


}