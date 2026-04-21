package com.godcount.rpass.autofill.helpers

import android.app.assist.AssistStructure
import android.os.Build
import android.text.InputType
import android.view.View
import android.view.autofill.AutofillId
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale
import java.util.Objects


class ViewStructureParser(private val structure: AssistStructure) {


    companion object {

        const val APPLICATION_ID_POPUP_WINDOW = "PopupWindow:"

        val AUTOFILL_USERNAME_FIELD = arrayOf("login", "username", "user", "name")
        val AUTOFILL_EMAIL_FIELD = arrayOf("emailAddress", "email", "mail")
        val AUTOFILL_OTP_FIELD =
            arrayOf("otp", "totp", "2faAppOTPCode", "one-time-code", "one-time-password")


        val ATTRIBUTES_USERNAME_FIELD = arrayOf("账号", "用户")
        val ATTRIBUTES_EMAIL_FIELD = arrayOf("邮箱")
        val ATTRIBUTES_OTP_FIELD = arrayOf(
            "2fa",
            "2fpin",
            "app_otp",
            "app_totp",
            "auth",
            "code",
            "idvpin",
            "challenge",
            "mfa",
            "mfacode",
            "otpcode",
            "token",
            "totppin",
            "tow-factor",
            "towfa",
            "towfactor",
            "verification_pin"
        )

    }

    var packageName: String? = null
    var webDomain: String? = null
    var webScheme: String? = null
    var fields = HashMap<String, AutofillId>()


    init {
        parse()
    }


    fun canAutofill(): Boolean {
        return fields.keys.contains(View.AUTOFILL_HINT_PASSWORD) || fields.keys.contains("otp")
    }


    fun toAutofillMetadata(manual: Boolean?): AutofillMetadata {
        return AutofillMetadata(fields.keys, manual, packageName, webDomain, webScheme)
    }


    private fun parse() {
        this.fields.clear()
        for (i in 0..<structure.windowNodeCount) {
            val windowNode = structure.getWindowNodeAt(i)
            val applicationId = windowNode.title.toString().split("/").first()
            if (!applicationId.contains(APPLICATION_ID_POPUP_WINDOW)) {
                packageName = applicationId
                parseNode(this.fields, windowNode.rootViewNode)
            }

        }
    }


    private fun parseNode(fields: HashMap<String, AutofillId>, node: AssistStructure.ViewNode) {
//        node.idPackage?.let {
//            packageName = it
//        }

        node.webDomain?.let {
            if (it.isNotEmpty()) {
                webDomain = it
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            node.webScheme?.let {
                if (it.isNotEmpty()) {
                    webScheme = it
                }
            }
        }

        if (node.visibility == View.VISIBLE) {
            if (node.autofillId != null) {
                parseField(node)?.let {
                    if (!fields.contains(it)) {
                        fields[it] = node.autofillId!!
                    }
                }
            }

            for (i in 0..<node.childCount) {
                parseNode(fields, node.getChildAt(i))
            }
        }


    }

    private fun parseField(node: AssistStructure.ViewNode): String? {
        return if (!node.autofillHints.isNullOrEmpty()) {
            parseAutofillHint(node)
        } else {
            parseHtmlInfo(node) ?: parseInput(node)
        }
    }


    private fun parseAutofillHint(node: AssistStructure.ViewNode): String? {
        return node.autofillHints?.let {
            for (item in it) {
                val value = item.lowercase(Locale.ENGLISH)

                if (value.contains(View.AUTOFILL_HINT_PASSWORD)) {
                    return View.AUTOFILL_HINT_PASSWORD
                } else if (AUTOFILL_USERNAME_FIELD.contains(value)) {
                    return View.AUTOFILL_HINT_USERNAME
                } else if (AUTOFILL_EMAIL_FIELD.contains(value)) {
                    return "email"
                } else if (AUTOFILL_OTP_FIELD.contains(value)) {
                    return "otp"
                } else if (value == "off" || value == "on") {
                    return parseHtmlInfo(node)
                }
            }
            null
        }
    }

    private fun parseHtmlInfo(node: AssistStructure.ViewNode): String? {
        if (node.htmlInfo?.tag.equals("input", true)) {
            node.htmlInfo!!.attributes?.let {
                var fallback: String? = null
                for (item in node.htmlInfo!!.attributes!!) {

                    if (item.first == null || item.second == null)
                        continue

                    val first = item.first.lowercase(Locale.ENGLISH)
                    val second = item.second.lowercase(Locale.ENGLISH)

                    if (first == "id" || first == "name") {
                        when {
                            AUTOFILL_OTP_FIELD.contains(second) ||
                                    ATTRIBUTES_OTP_FIELD.contains(second) -> {
                                return "otp"
                            }

                            AUTOFILL_USERNAME_FIELD.contains(second) ||
                                    ATTRIBUTES_USERNAME_FIELD.contains(second) -> {
                                fallback = View.AUTOFILL_HINT_USERNAME
                            }

                            AUTOFILL_EMAIL_FIELD.contains(second) ||
                                    ATTRIBUTES_EMAIL_FIELD.contains(second) -> {
                                fallback = View.AUTOFILL_HINT_USERNAME
                            }

                        }

                    } else if (first == "type") {
                        when (second) {
                            "tel", "text" -> {
                                fallback = View.AUTOFILL_HINT_USERNAME
                            }

                            "email" -> {
                                return "email"
                            }

                            View.AUTOFILL_HINT_PASSWORD -> {
                                return View.AUTOFILL_HINT_PASSWORD
                            }
                        }
                    }


                }
                return fallback
            }
        }

        return null
    }

    private fun parseInput(node: AssistStructure.ViewNode): String? {
        val inputType = node.inputType
        when (inputType and InputType.TYPE_MASK_CLASS) {
            InputType.TYPE_CLASS_TEXT -> {
                return manageTypeText(inputType)
            }

            InputType.TYPE_CLASS_NUMBER -> {
                return manageTypeNumber(inputType)
            }
        }
        return null
    }


    private fun manageTypeText(inputType: Int): String? {
        when {
            inputIsVariationType(
                inputType,
                InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS,
                InputType.TYPE_TEXT_VARIATION_WEB_EMAIL_ADDRESS
            ) -> {
                return "email"
            }

            inputIsVariationType(
                inputType,
                InputType.TYPE_TEXT_VARIATION_NORMAL,
                InputType.TYPE_TEXT_VARIATION_PERSON_NAME,
                InputType.TYPE_TEXT_VARIATION_WEB_EDIT_TEXT
            ) -> {
                return View.AUTOFILL_HINT_USERNAME
            }

            inputIsVariationType(
                inputType,
                InputType.TYPE_TEXT_VARIATION_PASSWORD,
                InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD,
                InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD
            ) -> {
                return View.AUTOFILL_HINT_PASSWORD
            }


        }
        return null
    }

    private fun manageTypeNumber(inputType: Int): String? {
        when {
            inputIsVariationType(
                inputType,
                InputType.TYPE_NUMBER_VARIATION_NORMAL
            ) -> {
                return View.AUTOFILL_HINT_USERNAME
            }

            inputIsVariationType(
                inputType,
                InputType.TYPE_NUMBER_VARIATION_PASSWORD
            ) -> {
                return View.AUTOFILL_HINT_PASSWORD
            }
        }
        return null
    }

    private fun inputIsVariationType(inputType: Int, vararg type: Int): Boolean {
        type.forEach {
            if (inputType and InputType.TYPE_MASK_VARIATION == it)
                return true
        }
        return false
    }


    private fun debug(node: AssistStructure.ViewNode) {
        println(
            "node info: " +
                    "autofillId: ${node.autofillId}; " +
                    "visibility: ${node.visibility == View.VISIBLE}; " +
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

}


data class AutofillMetadata(
    val fieldTypes: Set<String>,
    val manual: Boolean?,
    val packageName: String?,
    val webDomain: String?,
    val webScheme: String?,
) {
    companion object {
        const val EXTRA_AUTOFILL_METADATA = "com.godcount.rpass.AUTOFILL_METADATA"

        fun fromJsonString(json: String) =
            JSONObject(json).run {
                AutofillMetadata(
                    fieldTypes = optJSONArray("fieldTypes")?.map { array, index ->
                        array.getString(index)
                    }?.toSet() ?: HashSet(),
                    manual = get("manual") as? Boolean,
                    packageName = get("packageName") as? String,
                    webDomain = get("webDomain") as? String,
                    webScheme = get("webScheme") as? String,
                )
            }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is AutofillMetadata) return false
        return packageName == other.packageName &&
                webDomain == other.webDomain &&
                webScheme == other.webScheme &&
                fieldTypes == other.fieldTypes
    }

    override fun hashCode(): Int {
        return Objects.hash(packageName, webDomain, webScheme, fieldTypes)
    }

    fun toMap(): Map<Any, Any?> = mapOf(
        "fieldTypes" to fieldTypes.toList(),
        "manual" to manual,
        "packageName" to packageName,
        "webDomain" to webDomain,
        "webScheme" to webScheme,
    )

    fun toJsonString(): String = JSONObject(toMap()).toString()
}

fun <T> JSONArray.map(f: (array: JSONArray, index: Int) -> T): List<T> {
    return (0 until length()).map { index ->
        f(this, index)
    }
}


