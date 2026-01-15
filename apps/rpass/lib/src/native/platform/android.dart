import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../channel.dart';

final _logger = Logger("native:android");

enum AutofillServiceStatus {
  unsupported,
  disabled,
  enabled,
}

class AutofillField {
  static const PASSWORD = "password";
  static const USERNAME = "username";
  static const EMAIL = "email";
  static const OTP = "otp";
}

class AutofillMetadata {
  AutofillMetadata({
    required this.packageNames,
    required this.webDomains,
    required this.fieldTypes,
  });

  factory AutofillMetadata.fromJson(Map<dynamic, dynamic> json) =>
      AutofillMetadata(
        packageNames: (json['packageNames'] as Iterable)
            .map((dynamic e) => e as String)
            .toSet(),
        webDomains: (json['webDomains'] as Iterable)
            .map((dynamic e) =>
                AutofillWebDomain.fromJson(e as Map<dynamic, dynamic>))
            .toSet(),
        fieldTypes: (json['fieldTypes'] as Iterable)
            .map((dynamic e) => e as String)
            .toSet(),
      );

  final Set<String> packageNames;
  final Set<AutofillWebDomain> webDomains;
  final Set<String> fieldTypes;

  @override
  String toString() => toJson().toString();

  Map<String, Object> toJson() => {
        'packageNames': packageNames,
        'webDomains': webDomains.map((e) => e.toJson()),
        'fieldTypes': fieldTypes,
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

  Map<String, Object?> toJson() => {
        'scheme': scheme,
        'domain': domain,
      };
}

class AutofillDataset {
  AutofillDataset({
    this.label,
    this.username,
    this.password,
    this.otp,
  });

  final String? label;
  final String? username;
  final String? password;
  final String? otp;

    @override
  String toString() => toJson().toString();

  Map<String, Object?> toJson() => {
        'label': label,
        'username': username,
        'password': password,
        'otp': otp,
      };
}

class AutofillService {
  Future<AutofillServiceStatus> status() async {
    return AutofillServiceStatus.unsupported;
  }

  Future<AutofillMetadata?> metadata() async {
    return null;
  }

  Future<bool> responseDataset(List<AutofillDataset> list) async {
    return false;
  }

  Future<bool> enabled() async {
    return false;
  }

  Future<void> disabled() async {
    return;
  }
}

class _AndroidAutofillService extends AutofillService {
  _AndroidAutofillService(this.channel);

  final MethodChannel channel;

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
    return await channel
            .invokeMethod<bool>("request_enabled_autofill_service") ??
        false;
  }

  @override
  Future<void> disabled() async {
    await channel.invokeMethod("disabled_autofill_service");
  }

  @override
  Future<AutofillMetadata?> metadata() async {
    final result = await channel
        .invokeMapMethod<dynamic, dynamic>("get_autofill_metadata");
    return result != null ? AutofillMetadata.fromJson(result) : null;
  }

  @override
  Future<bool> responseDataset(List<AutofillDataset> list) async {
    return await channel.invokeMethod(
      "response_autofill_dataset",
      list.map((it) => it.toJson()).toList(),
    );
  }
}

class AndroidNativeInstancePlatform extends NativeInstancePlatform {
  AndroidNativeInstancePlatform() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  final MethodChannel _channel = const MethodChannel('native_channel_rpass');

  late final _AndroidAutofillService _autofillService =
      _AndroidAutofillService(_channel);

  @override
  AutofillService get autofillService => _autofillService;

  Future<void> _methodCallHandler(MethodCall call) async {
    debugPrint("native_channel: ${call.method}, ${call.arguments}");
  }
}
