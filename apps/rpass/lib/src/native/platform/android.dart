import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:logging/logging.dart';

import '../channel.dart';

final _logger = Logger("native:android");

enum AutofillServiceStatus { unsupported, disabled, enabled }

class AutofillField {
  static const PASSWORD = "password";
  static const USERNAME = "username";
  static const EMAIL = "email";
  static const OTP = "otp";
}

class AutofillService {
  Future<AutofillServiceStatus> status() async {
    return AutofillServiceStatus.unsupported;
  }

  Future<AutofillMetadata?> metadata() async {
    return null;
  }

  Future<bool> responseDataset(AutofillDataset dataset) async {
    return false;
  }

  Future<bool> enabled() async {
    return false;
  }

  Future<void> disabled() async {
    return;
  }
}

class _AndroidAutofillService extends MethodChannelInterface
    implements AutofillService {
  _AndroidAutofillService(super.channel, super.emit);

  @override
  final List<String> methodCalls = ["request_autofill_metadata"];

  @override
  Future<AutofillServiceStatus> status() async {
    final result = await channel.invokeMethod<bool>("autofill_service_status");
    return result == null
        ? AutofillServiceStatus.unsupported
        : result
        ? AutofillServiceStatus.enabled
        : AutofillServiceStatus.disabled;
  }

  @override
  Future<bool> enabled() async {
    return await channel.invokeMethod<bool>(
          "request_enabled_autofill_service",
        ) ??
        false;
  }

  @override
  Future<void> disabled() async {
    await channel.invokeMethod("disabled_autofill_service");
  }

  @override
  Future<AutofillMetadata?> metadata() async {
    final result = await channel.invokeMapMethod<dynamic, dynamic>(
      "get_autofill_metadata",
    );
    return result != null ? AutofillMetadata.fromJson(result) : null;
  }

  @override
  Future<bool> responseDataset(AutofillDataset dataset) async {
    return await channel.invokeMethod(
      "response_autofill_dataset",
      dataset.toJson(),
    );
  }

  @override
  Future<dynamic> onMethodCallHandler(MethodCall call) async {
    if (call.method == "request_autofill_metadata") {
      try {
        final metadata = AutofillMetadata.fromJson(call.arguments["metadata"]);
        emit((listener) => listener.onRequestAutofill(metadata));
      } catch (e) {
        _logger.warning("request autofill metadata $e");
      }
    }
  }
}

class AndroidNativeInstancePlatform extends NativeInstancePlatform {
  AndroidNativeInstancePlatform() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  final MethodChannel _channel = const MethodChannel('native_channel_rpass');

  late final _AndroidAutofillService _autofillService = _AndroidAutofillService(
    _channel,
    emit,
  );

  @override
  AutofillService get autofillService => _autofillService;

  late final List<MethodChannelInterface> _services = [_autofillService];

  Future<void> _methodCallHandler(MethodCall call) async {
    debugPrint("_methodCallHandler ${call.method}");
    for (final service in _services) {
      if (service.methodCalls.contains(call.method)) {
        return service.onMethodCallHandler(call);
      }
    }
  }
}
