package com.godcount.rpass.autofill.helpers

import android.app.assist.AssistStructure
import android.os.Build
import android.view.View
import android.view.autofill.AutofillId
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale


class ViewStructureParser(private val structure: AssistStructure) {


    companion object {
        val ATTRIBUTES_PASSWORD_MATCHES = Regex("password|密码")
        val ATTRIBUTES_USERNAME_MATCHES = Regex("login|username|user|name|账号|用户")
        val ATTRIBUTES_EMAIL_ADDRESS_MATCHES = Regex("email|mail|邮箱")
        val ATTRIBUTES_OTP_MATCHES = Regex("otp")
    }

    var packageName = HashSet<String>()
    var webDomain = HashSet<WebDomain>()
    var fields = HashMap<String, AutofillId>()


    init {
        parse()
    }


    fun canAutofill(): Boolean {
        for (key in fields.keys) {
            if (ATTRIBUTES_PASSWORD_MATCHES.containsMatchIn(key) || ATTRIBUTES_OTP_MATCHES.containsMatchIn(
                    key
                )
            ) {
                return true
            }
        }
        return false
    }


    fun toAutofillMetadata(): AutofillMetadata {
        return AutofillMetadata(packageName, webDomain, fields.keys)
    }


    private fun parse() {
        val fields = HashMap<String, AutofillId>()
        for (i in 0..<structure.windowNodeCount) {
            val node = structure.getWindowNodeAt(i).rootViewNode
            parseNode(fields, node)
        }

        var i = 0
        for (item in fields) {
            if (item.key == item.value.toString()) {
                this.fields["Field:$i-"] = item.value
            } else {
                this.fields[item.key] = item.value
            }
            i++
        }

    }


    private fun parseNode(fields: HashMap<String, AutofillId>, node: AssistStructure.ViewNode) {
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

        if (node.autofillType == View.AUTOFILL_TYPE_TEXT) {
            if (!fields.containsValue(node.autofillId)) {
                fields[getFieldKey(fields, node)] = node.autofillId!!
            }
        }
        for (i in 0..<node.childCount) {
            parseNode(fields, node.getChildAt(i))
        }
    }


    private fun getFieldKey(
        fields: HashMap<String, AutofillId>,
        node: AssistStructure.ViewNode
    ): String {

        if (!node.autofillHints.isNullOrEmpty()) {
            val key = node.autofillHints!![0].lowercase(Locale.getDefault())
            if (!fields.containsKey(key)) return key
        }


        if (!node.hint.isNullOrEmpty()) {
            val key = node.hint!!.lowercase(Locale.getDefault())
            if (!fields.containsKey(key)) return key
        }



        return node.htmlInfo?.let {
            var name: String? = null
            var id: String? = null

            for (it in it.attributes!!) {
                val first = it.first.lowercase(Locale.getDefault())
                val second = it.second.lowercase(Locale.getDefault())

                when (first) {
                    "type" -> return second
                    "name" -> name = second
                    "id" -> id = second
                }
            }

            name ?: id

        } ?: node.autofillId.toString()

    }


}


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
        const val EXTRA_AUTOFILL_METADATA = "com.godcount.rpass.AUTOFILL_METADATA"
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

    fun equal(data: AutofillMetadata): Boolean {
        return packageNames.containsAll(data.packageNames) &&
                webDomains.containsAll(data.webDomains) &&
                fieldTypes.containsAll(data.fieldTypes)
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


