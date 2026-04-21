package com.godcount.rpass

import android.content.Context
import android.util.Log
import io.flutter.plugins.sharedpreferences.JSON_LIST_PREFIX
import io.flutter.plugins.sharedpreferences.SHARED_PREFERENCES_NAME
import org.json.JSONArray

object PreferencesHelper {
    private const val TAG = "PreferencesHelper"

    private fun getString(context: Context, key: String): String? {
        val preferences =
            context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE)
        return if (preferences.contains(key)) {
            preferences.getString(key, "")
        } else {
            null
        }
    }

    private fun getStringList(
        context: Context,
        key: String,
    ): List<String>? {
        val stringValue = getString(context, key)
        stringValue?.let {
            // The JSON-encoded lists use an extended prefix to distinguish them from
            // lists that using listEncoder.
            return if (stringValue.startsWith(JSON_LIST_PREFIX)) {
                JSONArray(stringValue.substring(JSON_LIST_PREFIX.length)).let { array ->
                    List(array.length()) { array.getString(it) }
                }
            } else {
                null
            }
        }
        return null
    }


    fun getAutoFillAppIdBlacklist(context: Context): Set<String> {
        return try {
            getStringList(
                context,
                "flutter.autofill_appid_blacklist"
            )?.toSet() ?: emptySet()
        } catch (e: Throwable) {
            Log.w(TAG, "getAutoFillAppIdBlacklist error", e)
            emptySet()
        }
    }


    fun getAutoFillDomainBlacklist(context: Context): Set<String> {
        return try {
            getStringList(
                context,
                "flutter.autofill_domain_blacklist"
            )?.toSet() ?: emptySet()
        } catch (e: Throwable) {
            Log.w(TAG, "getAutoFillDomainBlacklist error", e)
            emptySet()
        }
    }


}