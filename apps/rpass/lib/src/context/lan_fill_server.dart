import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lan_fill_server/lan_fill_server.dart';

import '../page/route.dart';
import '../rpass.dart';
import '../store/index.dart';
import '../util/common.dart';
import '../widget/common.dart';
import '../widget/extension_state.dart';

class LanFillInherited extends InheritedWidget {
  const LanFillInherited({
    super.key,
    required this.cilentConnecting,
    required this.serverClosed,
    required this.openQrCodeDialog,
    required this.openQrCodeScanner,
    required super.child,
  });

  final bool cilentConnecting;
  final bool serverClosed;

  final ValueGetter<Future<void>> openQrCodeDialog;
  final ValueGetter<Future<void>> openQrCodeScanner;

  static LanFillInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LanFillInherited>();
  }

  @override
  bool updateShouldNotify(covariant LanFillInherited oldWidget) {
    return oldWidget.cilentConnecting != cilentConnecting ||
        oldWidget.serverClosed != serverClosed;
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
        getQrData: () async {
          try {
            dto ??= await _server!.start();
            return (
              jsonEncode(dto!.toJson()),
              _server!.certificateTotp.nextInterval(),
            );
          } finally {
            dto = null;
          }
        },
      );
    } catch (e) {
      showError(e);
    }
  }

  Future<void> openQrCodeScanner() async {
    try {
      final result = await context.router.push(QrCodeScannerRoute());
      if (result == null || result is! String) return;
      final data = RegisterDto.formJson(jsonDecode(result));

      _cilent ??= LanFillCilent(
        this,
        LanFillCilentOption(
          deviceInfo: DeviceInfoDto(
            deviceName: Platform.localHostname,
            appVersion: RpassInfo.version,
            fingerprint:
                Store.instance.settings.securityContext.certificateHash,
          ),
        ),
      );

      await _cilent!.register(data);
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
    _server?.close();
    _cilent?.close();
  }

  @override
  Widget build(BuildContext context) {
    return LanFillInherited(
      cilentConnecting: _cilent?.connecting ?? false,
      serverClosed: _server?.isClosed ?? false,
      openQrCodeDialog: openQrCodeDialog,
      openQrCodeScanner: openQrCodeScanner,
      child: widget.child,
    );
  }
}
