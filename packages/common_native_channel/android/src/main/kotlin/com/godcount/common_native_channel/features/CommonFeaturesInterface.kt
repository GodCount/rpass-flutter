package com.godcount.common_native_channel.features

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

interface CommonFeaturesInterface {
    val methods: Array<String>
    val channel: MethodChannel
    fun handle(call: MethodCall, result: MethodChannel.Result)
}