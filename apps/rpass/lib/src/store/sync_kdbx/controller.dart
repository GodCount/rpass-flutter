import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:logging/logging.dart';
import 'package:remote_fs/remote_fs.dart';

import '../../context/biometric.dart';
import '../../context/kdbx.dart';
import '../../page/route.dart';
import '../../rpass.dart';
import '../../remotes_fs/remote_fs.dart';
import '../index.dart';

final _logger = Logger("store:sync_kdbx");

class SyncKdbxController with ChangeNotifier {
  RemoteFileConfig? _config;
  RemoteFileConfig? get config => _config;

  Object? _lastError;
  Object? get lastError => _lastError;

  MergeLog? _lastMergeLog;
  MergeLog? get lastMergeLog => _lastMergeLog;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> setRemoteFileConfig(
    BuildContext context,
    RemoteFileConfig config,
  ) async {
    RemoteFile remoteFile = await config.open();

    if (!await remoteFile.exists()) {
      if (!remoteFile.name.endsWith(".kdbx")) {
        await remoteFile.mkdir();
        remoteFile = await remoteFile.relative(
          RpassInfo.defaultSyncKdbxFileName,
        );
      }
    } else {
      final stat = await remoteFile.stat();
      if (stat.type == .directory) {
        remoteFile = await remoteFile.relative(
          RpassInfo.defaultSyncKdbxFileName,
        );
      }
    }

    _config = await remoteFile.toConfig();

    return sync(context);
  }

  Future<void> sync(BuildContext context, {bool forceMerge = false}) async {
    try {
      _lastError = null;
      _lastMergeLog = null;

      _isSyncing = true;
      notifyListeners();

      final kdbxProvider = KdbxProvider.of(context);

      final kdbx = kdbxProvider.kdbx!;

      if (_config == null) {
        final entry = await kdbxProvider.getSyncEntryData();
        _config = entry != null
            ? RemoteFileKdbxEntryField.fromKdbx(entry)
            : null;
      }

      if (_config == null) {
        _logger.info("Remote config is null, Unable to synchronize.");
        return;
      }

      RemoteFile remoteFile = await _config!.open();
      final localFile = Store.instance.localInfo.localKdbxFile;

      if (!await remoteFile.exists()) {
        remoteFile.write(await localFile.readAsBytes());
        Store.instance.settings.setLastSyncTime(DateTime.now());
        return;
      }

      final stat = await remoteFile.stat();

      if (stat.type != .file) {
        throw Exception("not a file");
      }

      final remoteData = await remoteFile.read();
      Kdbx remoteKdbx;

      try {
        remoteKdbx = await Kdbx.openBytes(
          bytes: remoteData,
          credentials: Credentials.formCompositeKey(
            key: await kdbx.getCompositeKey(),
          ),
        );
      } catch (e) {
        _logger.warning("local credentials Unable open remote kdbx.", e);
        final result = await context.router.push(
          LoadExternalKdbxRoute(kdbxFile: remoteData),
        );

        if (result != null && result is (Kdbx, String?)) {
          remoteKdbx = result.$1;
        } else {
          _logger.info("sync cancel");
          return;
        }
      }

      _lastMergeLog = await kdbx.merge(kdbx: remoteKdbx);

      Store.instance.settings.setLastSyncTime(DateTime.now());

      _logger.info("merge save in local.");

      if (_lastMergeLog!.isUpdateMasterKey) {
        final biometric = Biometric.of(context);

        if (biometric.enable) {
          try {
            _logger.info("update biometric");
            await biometric.updateCredentials(
              context,
              await kdbx.getCompositeKey(),
            );
          } catch (e) {
            _logger.warning("update biometric failed! remove biometric data");
            Store.instance.settings.seEnableBiometric(false);
            await biometric.updateCredentials(context, null);
          }
        }
      }

      _logger.info(
        "{masterKeyChanged=${_lastMergeLog?.masterKeyChanged}, "
        "forceMerge=$forceMerge}",
      );

      // 在这种情况下需要更新远程文件
      if (_lastMergeLog!.masterKeyChanged ||
          _lastMergeLog!.events.isNotEmpty ||
          forceMerge) {
        await remoteFile.write(await kdbx.save());
        _logger.info("sync data write to remote file, done.");
      } else {
        // 没有变化
        _lastMergeLog = null;
      }
    } catch (e) {
      _lastError = e;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
