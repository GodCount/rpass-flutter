import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lan_fill_server/lan_fill_server.dart';

import '../rpass.dart';
import '../store/index.dart';
import '../util/common.dart';
import '../widget/common.dart';
import '../widget/extension_state.dart';

class LanFill extends InheritedWidget {
  const LanFill({super.key, required super.child});

  @override
  bool updateShouldNotify(covariant LanFill oldWidget) {
    // TODO: implement updateShouldNotify
    throw UnimplementedError();
  }
}

class LanFillServerProvider extends StatefulWidget {
  const LanFillServerProvider({super.key, required this.child});

  final Widget child;

  @override
  State<LanFillServerProvider> createState() => _LanFillServerState();
}

class _LanFillServerState extends State<LanFillServerProvider>
    with InteractiveManipulation {
  LanFillCilent? _cilent;
  LanFillServer? _server;

  final SimpleAsyncQueue _validateFingerprintQueue = SimpleAsyncQueue();

  // 不信任的指纹
  // 每次弹出二维码窗口时重置
  final List<String> _distrustList = [];

  Future<void> openQrCodeDialog() async {
    try {
      _distrustList.clear();

      _server ??= LanFillServer(
        this,
        LanFillServerOption(
          deviceInfo: DeviceInfoDto(
            deviceName: Platform.localHostname,
            appVersion: RpassInfo.version,
            fingerprint:
                Store.instance.settings.securityContext.certificateHash,
          ),
          securityContext: Store.instance.settings.securityContext,
        ),
      );
      RegisterDto? dto = await _server!.start();

      QrCodeDialog.openDialog(
        context,
        refreshDuration: _server!.option.secretKeyInterval,
        getQrData: () async {
          try {
            dto ??= await _server!.start();
            return jsonEncode(dto!.toJson());
          } finally {
            dto = null;
          }
        },
      );
    } catch (e) {
      showError(e);
    }
  }

  @protected
  @override
  Future<bool> validateFingerprint(
    String fingerprint,
    String devicePlatform,
    String? deviceName,
  ) async {
    if (_distrustList.contains(fingerprint)) {
      return false;
    }

    if (Store.instance.settings.trustFingerprints.contains(fingerprint)) {
      return true;
    }

    return _validateFingerprintQueue.add(() async {
      if (_distrustList.contains(fingerprint)) {
        return false;
      }

      if (Store.instance.settings.trustFingerprints.contains(fingerprint)) {
        return true;
      }

      if (await showConfirmDialog(
        title: "未知设备",
        message: "名称: $deviceName\n平台: $devicePlatform",
        cancel: "禁止",
        confirm: "信任",
      )) {
        Store.instance.settings.setTrustFingerprints([
          ...Store.instance.settings.trustFingerprints,
          fingerprint,
        ]);
        return true;
      }
      _distrustList.add(fingerprint);
      return false;
    });
  }

  @protected
  @override
  Future<void> remoteAutofill(AutofillDto dto) {
    // TODO: implement remoteAutofill
    throw UnimplementedError();
  }

  @protected
  @override
  void onCilentClose() {
    _validateFingerprintQueue.clear();
  }

  @protected
  @override
  void onServerClose() {
    _validateFingerprintQueue.clear();
  }

  @override
  void dispose() {
    super.dispose();
    _validateFingerprintQueue.clear();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
