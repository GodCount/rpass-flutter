import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lan_fill_server/lan_fill_server.dart';
import 'package:path/path.dart' as path;

import '../i18n.dart';
import '../kdbx/auto_fill.dart';
import '../kdbx/kdbx.dart';
import '../page/route.dart';
import '../rpass.dart';
import '../store/index.dart';
import '../util/common.dart';
import '../util/file.dart';
import '../widget/common.dart';
import '../widget/extension_state.dart';

typedef RequestRemoteAutofill = Future<void> Function(AutofillDto dto);
typedef UpdateFile = Future<void> Function(String filename, Uint8List bytes);

class LanFillInherited extends InheritedWidget {
  const LanFillInherited({
    super.key,
    required this.cilentConnecting,
    required this.serverClosed,
    required this.openQrCodeDialog,
    required this.openQrCodeScanner,
    required this.requestRemoteAutofill,
    required this.updateFile,

    required super.child,
  });

  final bool cilentConnecting;
  final bool serverClosed;

  final ValueGetter<Future<void>> openQrCodeDialog;
  final ValueGetter<Future<void>> openQrCodeScanner;
  final RequestRemoteAutofill requestRemoteAutofill;
  final UpdateFile updateFile;

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
  final SimpleAsyncQueue _requestQueue = SimpleAsyncQueue();

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

      setState(() {});

      await QrCodeDialog.openDialog(
        context,
        title: I18n.of(context)!.lan_fill,
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
        onClose: () {
          _server?.close();
        },
      );
    } catch (e, s) {
      showError("$e\n$s");
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
    } catch (e, s) {
      showError("$e\n$s");
    }
  }

  Future<bool> _ping() async {
    if ((await _cilent?.heartbeat()) != true) {
      await openQrCodeScanner();
    }

    return _cilent?.connecting ?? false;
  }

  Future<void> requestRemoteAutofill(AutofillDto dto) async {
    try {
      if (await _ping()) {
        await _cilent!.autofill(dto);
      }
    } catch (e, s) {
      showError("$e\n$s");
    }
  }

  Future<void> updateFile(String filename, Uint8List bytes) async {
    try {
      if (await _ping()) {
        await _cilent!.uploadFile(filename, bytes);
      }
    } catch (e, s) {
      showError("$e\n$s");
    }
  }

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

      final t = I18n.of(context)!;

      if (await showConfirmDialog(
        title: t.unknown_device,
        message: "${t.device}: $deviceName\n${t.platform}: $devicePlatform",
        cancel: t.cancel,
        confirm: t.trust,
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

  @override
  Future<void> onRemoteAutofill(AutofillDto dto) async {
    await _requestQueue.add(() async {
      await autoFillSequence(
        defaultAutoTypeSequence,
        key: dto.key,
        getValue: (key) => dto.fields[key],
      );
    });
  }

  @override
  Future<void> onSaveUploadFile(String filename, Uint8List bytes) async {
    try {
      await _requestQueue.add(() async {
        await SimpleFile.saveFile(
          data: bytes,
          filename: path.basename(filename),
        );
      });
    } catch (e) {
      if (e is! CancelException) {
        showError(e);
      }
    }
  }

  @override
  void onServerCilentFirstHeartbeat(String devicePlatform, String? deviceName) {
    // TODO! pop QrCodeDialog.openDialog 弹窗
    // ? 直接pop 可能有风险, 例如打开QrCodeDialog 进入 _BackgroundLock
    // 这时回调到这里直接pop 会把VerifyOwnerRoute 关掉 ?
  }

  @override
  void onCilentClose() {
    _validateFingerprintQueue.clear();
    setState(() {});
  }

  @override
  void onServerClose() {
    _validateFingerprintQueue.clear();
    setState(() {});
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
      serverClosed: _server?.isClosed ?? true,
      openQrCodeDialog: openQrCodeDialog,
      openQrCodeScanner: openQrCodeScanner,
      requestRemoteAutofill: requestRemoteAutofill,
      updateFile: updateFile,
      child: widget.child,
    );
  }
}
