package com.godcount.rpass.autofill

import android.app.PendingIntent
import android.app.assist.AssistStructure
import android.app.assist.AssistStructure.ViewNode
import android.content.Intent
import android.os.*
import android.service.autofill.*
import android.view.View
import android.view.autofill.AutofillId
import android.view.autofill.AutofillManager
import android.widget.RemoteViews
import androidx.annotation.DrawableRes
import com.godcount.rpass.MainActivity
import com.godcount.rpass.R
import org.json.JSONObject
import org.json.JSONArray


class MyAutofillService : AutofillService() {

    private var unlockLabel = "Rpass with Autofill"


    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback
    ) {
        val context = request.fillContexts.last()
        val structure = context.structure

        val parsedStructure = ParsedStructure(structure)

        if (!parsedStructure.canFill) {
            return callback.onSuccess(null)
        }

        val intent = Intent(applicationContext, MainActivity::class.java)
        intent.action = Intent.ACTION_RUN
        intent.putExtra(
            AutofillMetadata.EXTRA_NAME,
            AutofillMetadata(
                parsedStructure.packageName,
                parsedStructure.webDomain,
                parsedStructure.fieldTypes
            ).toJsonString()
        )
        intent.putExtra(AutofillManager.EXTRA_ASSIST_STRUCTURE, structure)

        val sender = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_CANCEL_CURRENT
        ).intentSender


        val fillResponse = FillResponse.Builder().setAuthentication(
            parsedStructure.autoFillIds.distinct().toTypedArray(),
            sender,
            RemoteViewsHelper.viewsWithAuth(packageName, unlockLabel, null)
        ).build()

        callback.onSuccess(fillResponse)

    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        callback.onFailure("Not yet implemented")
    }
}

object RemoteViewsHelper {

    fun viewsWithAuth(packageName: String, title: String?, subtitle: String?): RemoteViews {
        return simpleRemoteViews(packageName, R.drawable.ic_lock_black_24dp, title, subtitle)
    }

    fun viewsWithNoAuth(packageName: String, title: String?, subtitle: String?): RemoteViews {
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

class ParsedStructure(structure: AssistStructure) {


    companion object {
        private val ATTRIBUTES_PASSWORD_MATCHES = Regex("password|密码")
        private val ATTRIBUTES_USERNAME_MATCHES = Regex("login|username|user|name|账号|用户")
        private val ATTRIBUTES_EMAIL_ADDRESS_MATCHES = Regex("email|mail|邮箱")
        private val ATTRIBUTES_OTP_MATCHES = Regex("otp")
    }

    var packageName = HashSet<String>()
    var webDomain = HashSet<WebDomain>()

    val fields = HashSet<AutofillFieldType>()

    val autoFillIds get() = fields.toList().map { it.autofillId }
    val fieldTypes get() = fields.toList().map { it.type }.toSet()
    val canFill
        get() = fieldTypes.any {
            it.contains(FieldType.PASSWORD) || it.contains(FieldType.USERNAME)
                    || it.contains(FieldType.EMAIL) || it.contains(FieldType.OTP)
        }

    init {
        traverseStructure(structure)
    }


    private fun traverseStructure(structure: AssistStructure) {
        val windowNodes: List<AssistStructure.WindowNode> =
            structure.run {
                (0 until windowNodeCount).map { getWindowNodeAt(it) }
            }

        windowNodes.forEach { windowNode: AssistStructure.WindowNode ->
            windowNode.rootViewNode?.let { traverseNode(it) }
        }
    }

    private fun traverseNode(node: ViewNode) {
        node.idPackage?.let { packageName.add(it) }
        node.webDomain?.let {
            webDomain.add(
                WebDomain(
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        node.webScheme
                    } else {
                        null
                    }, it
                )
            )
        }

        node.autofillId?.let {
            val type = getFieldType(node)
            debug(node, type)

            fields.add(AutofillFieldType(it, type, node))
        }


        node.run {
            (0 until childCount).forEach {
                traverseNode(getChildAt(it))
            }
        }


    }

    private fun debug(node: ViewNode, type: String) {
        println(
            "node info: " +
                    "type: $type; " +
                    "className: ${node.className.toString()}; " +
                    "idPackage: ${node.idPackage}; " +
                    "webDomain: ${node.webDomain}; " +
                    "inputType: ${node.inputType}; " +
                    "autofillType: ${node.autofillType}; " +
                    "idEntry: ${node.idEntry}; " +
                    "hint: ${node.hint}; " +
                    "isOpaque: ${node.isOpaque}; " +
                    "isFocusable: ${node.isFocusable}; " +
                    "isChecked: ${node.isChecked}; " +
                    "isEnabled: ${node.isEnabled}; " +
                    "isFocused: ${node.isFocused}; " +
                    "isAccessibilityFocused: ${node.isAccessibilityFocused}; " +
                    "isActivated: ${node.isActivated}; " +
                    "isAssistBlocked: ${node.isAssistBlocked}; " +
                    "isCheckable: ${node.isCheckable}; " +
                    "isClickable: ${node.isClickable}; " +
                    "isContextClickable: ${node.isContextClickable}; " +
                    "isLongClickable: ${node.isLongClickable}; " +
                    "isSelected: ${node.isSelected}; " +
                    "htmlInfo: ${
                        node.htmlInfo?.attributes?.toTypedArray()?.contentDeepToString()
                    }; " +
                    "autofillHints: ${node.autofillHints.contentDeepToString()}"
        )
    }

    private fun getFieldType(node: ViewNode): String {
        return when {
            isPasswordField(node) -> FieldType.PASSWORD
            isEmailField(node) -> FieldType.EMAIL
            isUserNameField(node) -> FieldType.USERNAME
            isOtpField(node) -> FieldType.OTP
            else -> node.autofillHints?.joinToString("|")
                ?: node.htmlInfo?.attributes?.joinToString("|") { "${it.first}:${it.second}" }
                ?: "unknown"
        }
    }

    private fun isPasswordField(node: ViewNode): Boolean {

        if (node.autofillType == View.AUTOFILL_TYPE_NONE) return false


        return node.autofillHints?.any {
            ATTRIBUTES_PASSWORD_MATCHES.containsMatchIn(it.lowercase())
        } ?: node.htmlInfo?.attributes?.any {
            it.second != null && ATTRIBUTES_PASSWORD_MATCHES.containsMatchIn(it.second.lowercase())
        } ?: node.hint?.let {
            ATTRIBUTES_PASSWORD_MATCHES.containsMatchIn(it.lowercase())
        } ?: false
    }

    private fun isUserNameField(node: ViewNode): Boolean {

        if (node.autofillType == View.AUTOFILL_TYPE_NONE) return false

        return node.autofillHints?.any {
            ATTRIBUTES_USERNAME_MATCHES.containsMatchIn(it.lowercase())
        } == true || node.htmlInfo?.attributes?.any {
            it.second != null && ATTRIBUTES_USERNAME_MATCHES.containsMatchIn(it.second.lowercase())
        } == true || node.hint?.let {
            ATTRIBUTES_USERNAME_MATCHES.containsMatchIn(it.lowercase())
        } == true
    }

    private fun isEmailField(node: ViewNode): Boolean {

        if (node.autofillType == View.AUTOFILL_TYPE_NONE) return false

        return node.autofillHints?.any {
            ATTRIBUTES_EMAIL_ADDRESS_MATCHES.containsMatchIn(it.lowercase())
        } == true || node.htmlInfo?.attributes?.any {
            it.second != null && ATTRIBUTES_EMAIL_ADDRESS_MATCHES.containsMatchIn(it.second.lowercase())
        } == true || node.hint?.let {
            ATTRIBUTES_EMAIL_ADDRESS_MATCHES.containsMatchIn(it.lowercase())
        } == true

    }

    private fun isOtpField(node: ViewNode): Boolean {
        if (node.autofillType == View.AUTOFILL_TYPE_NONE) return false

        return node.autofillHints?.any {
            ATTRIBUTES_OTP_MATCHES.containsMatchIn(it.lowercase())
        } == true || node.htmlInfo?.attributes?.any {
            it.second != null && ATTRIBUTES_OTP_MATCHES.containsMatchIn(it.second.lowercase())
        } == true || node.hint?.let {
            ATTRIBUTES_OTP_MATCHES.containsMatchIn(it.lowercase())
        } == true
    }


}

class FieldType {
    companion object {
        const val PASSWORD = "password"
        const val USERNAME = "username"
        const val EMAIL = "email"
        const val OTP = "otp"
    }
}

data class AutofillFieldType(val autofillId: AutofillId, val type: String, val node: ViewNode)


data class WebDomain(val scheme: String?, val domain: String) {
    fun toMap() = mapOf(
        SCHEME to scheme,
        DOMAIN to domain,
    )

    companion object {
        private const val SCHEME = "scheme"
        private const val DOMAIN = "domain"

        fun fromJson(obj: JSONObject) =
            WebDomain(
                scheme = obj.optString(SCHEME),
                domain = obj.optString(DOMAIN),
            )
    }
}

data class AutofillMetadata(
    val packageNames: Set<String>,
    val webDomains: Set<WebDomain>,
    val fieldTypes: Set<String>,
) {
    companion object {
        const val EXTRA_NAME = "AutofillMetadata"
        private const val FIELD_TYPES = "fieldTypes"

        private const val PACKAGE_NAMES = "packageNames"
        private const val WEB_DOMAINS = "webDomains"

        fun fromJsonString(json: String) =
            JSONObject(json).run {
                AutofillMetadata(
                    packageNames = optJSONArray(PACKAGE_NAMES)?.map { array, index ->
                        array.getString(index)
                    }?.toSet() ?: HashSet(),
                    webDomains = optJSONArray(WEB_DOMAINS)?.map { array, index ->
                        WebDomain.fromJson(array.getJSONObject(index))
                    }?.toSet() ?: HashSet(),
                    fieldTypes = optJSONArray(FIELD_TYPES)?.map { array, index ->
                        array.getString(index)
                    }?.toSet() ?: HashSet()
                )
            }
    }

    fun toMap(): Map<Any, Any> = mapOf(
        PACKAGE_NAMES to packageNames.toList(),
        WEB_DOMAINS to webDomains.map { it.toMap() },
        FIELD_TYPES to fieldTypes.toList(),
    )

    fun toJsonString(): String = JSONObject(toMap()).toString()
}

fun <T> JSONArray.map(f: (array: JSONArray, index: Int) -> T): List<T> {
    return (0 until length()).map { index ->
        f(this, index)
    }
}



