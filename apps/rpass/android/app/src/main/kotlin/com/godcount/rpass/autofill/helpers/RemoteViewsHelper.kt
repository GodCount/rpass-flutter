package com.godcount.rpass.autofill.helpers

import android.view.View
import android.widget.RemoteViews
import androidx.annotation.DrawableRes
import com.godcount.rpass.R

object RemoteViewsHelper {

    fun viewsWithAuth(packageName: String, title: String?, subtitle: String?): RemoteViews {
        return simpleRemoteViews(packageName, R.drawable.ic_lock_black_24dp, title, subtitle)
    }

    fun viewsWithUser(packageName: String, title: String?, subtitle: String?): RemoteViews {
        return simpleRemoteViews(packageName, R.drawable.ic_person_black_24dp, title, subtitle)
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