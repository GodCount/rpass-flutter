import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

class AutofillMetadata {
  AutofillMetadata({
    required this.fieldTypes,

    this.packageName,
    this.webDomain,
    this.webScheme,
  });

  factory AutofillMetadata.fromJson(Map<dynamic, dynamic> json) =>
      AutofillMetadata(
        fieldTypes: (json['fieldTypes'] as Iterable)
            .map((dynamic e) => e as String)
            .toSet(),
        packageName: json['packageName'] as String?,
        webDomain: json['webDomain'] as String?,
        webScheme: json['webScheme'] as String?,
      );

  final String? packageName;
  final String? webDomain;
  final String? webScheme;
  final Set<String> fieldTypes;

  @override
  String toString() => toJson().toString();

  Map<String, Object?> toJson() => {
    'fieldTypes': fieldTypes,
    'packageName': packageName,
    'webDomain': webDomain,
    'webScheme': webScheme,
  };
}

class AutofillWebDomain {
  AutofillWebDomain({this.scheme, required this.domain});

  factory AutofillWebDomain.fromJson(Map<dynamic, dynamic> json) =>
      AutofillWebDomain(
        scheme: json['scheme'] as String?,
        domain: json['domain'] as String,
      );

  final String? scheme;
  final String domain;

  @override
  String toString() => toJson().toString();

  Map<String, Object?> toJson() => {'scheme': scheme, 'domain': domain};
}

enum AutofillDatasetStatus {
  AUTH, // 需要验证
  MANUAL, // 需要手动选择
  FILL, // 直接填充
}

class AutofillDataset {
  AutofillDataset({required this.status, this.message, required this.data});

  static final DATASET_FIELD_LABEL = "label";
  static final DATASET_FIELD_USERNAME = "username";
  static final DATASET_FIELD_EMAIL = "email";

  static final DATASET_FIELD_PASSWORD = "password";
  static final DATASET_FIELD_OTP = "otp";

  final AutofillDatasetStatus status;
  final String? message;
  final List<Map<String, String?>> data;

  @override
  String toString() => toJson().toString();

  Map<String, Object?> toJson() => {
    'status': status.name,
    'message': message,
    'data': data,
  };
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
        final manualSelect = call.arguments["manualSelect"] is bool
            ? call.arguments["manualSelect"] as bool? ?? false
            : false;
        emit((listener) => listener.onRequestAutofill(metadata, manualSelect));
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
