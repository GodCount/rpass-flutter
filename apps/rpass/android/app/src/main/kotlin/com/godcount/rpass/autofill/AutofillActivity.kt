package com.godcount.rpass.autofill

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT
import com.godcount.rpass.MainActivity
import com.godcount.rpass.R
import com.godcount.rpass.autofill.helpers.IntentBundleKey

class AutofillActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.autofill)

        val intent = Intent(this, MainActivity::class.java)

        if (this.intent.hasExtra(IntentBundleKey.EXTRA_AUTOFILL_BUNDLE)) {
            intent.putExtra(
                IntentBundleKey.EXTRA_AUTOFILL_BUNDLE,
                this.intent.getBundleExtra(IntentBundleKey.EXTRA_AUTOFILL_BUNDLE)
            )

            val receiver = object : ResultReceiver(Handler(Looper.getMainLooper())) {
                override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
                    super.onReceiveResult(resultCode, resultData)
                    setResult(
                        RESULT_OK,
                        Intent().putExtras(resultData ?: Bundle().apply {
                            putParcelable(EXTRA_AUTHENTICATION_RESULT, null)
                        })
                    )
                    finish()
                }
            }

            intent.putExtra(IntentBundleKey.EXTRA_RESULT_RECEIVER, receiver)

            intent.flags =
                Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK

            startActivity(intent)
        } else {
            setResult(0)
            finish()
        }
    }

}