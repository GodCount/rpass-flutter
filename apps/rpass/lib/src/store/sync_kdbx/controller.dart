import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:remote_fs/remote_fs.dart';

import '../../context/biometric.dart';
import '../../context/kdbx.dart';
import '../../page/route.dart';
import '../../rpass.dart';
import '../../kdbx/kdbx.dart';
import '../../remotes_fs/remote_fs.dart';
import '../index.dart';

final _logger = Logger("store:sync_kdbx");

class SyncKdbxController with ChangeNotifier {
  RemoteFileConfig? _config;
  RemoteFileConfig? get config => _config;

  Object? _lastError;
  Object? get lastError => _lastError;

  MergeContext? _lastMergeContext;
  MergeContext? get lastMergeContext => _lastMergeContext;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> initConfig(Kdbx kdbx) async {
    try {
      if (kdbx.syncAccountEntry != null) {
        _config = RemoteFileKdbxEntryField.fromKdbx(kdbx.syncAccountEntry!);
        if (_config == null) {
          kdbx.syncAccountEntry = null;
        }
      }
    } catch (e) {
      _logger.warning(e);
      kdbx.syncAccountEntry = null;
    }
  }

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
      _lastMergeContext = null;

      _isSyncing = true;
      notifyListeners();

      final kdbx = KdbxProvider.of(context).kdbx!;

      if (_config == null) {
        await initConfig(kdbx);
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
        remoteKdbx = await Kdbx.loadBytesFromCredentials(
          data: remoteData,
          credentials: kdbx.credentials,
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

      final syncMergeContext = await kdbx.sync(remoteKdbx);
      _lastMergeContext = syncMergeContext.mergeContext;

      Store.instance.settings.setLastSyncTime(DateTime.now());

      _logger.info("merge save in local.");

      if (syncMergeContext.isUpdateMasterKey) {
        final biometric = Biometric.of(context);

        if (biometric.enable) {
          try {
            _logger.info("update biometric");
            await biometric.updateCredentials(
              context,
              kdbx.credentials.getHash(),
            );
          } catch (e) {
            _logger.warning("update biometric failed! remove biometric data");
            Store.instance.settings.seEnableBiometric(false);
            await biometric.updateCredentials(context, null);
          }
        }
      }

      _logger.info(
        "{masterKeyChanged=${syncMergeContext.masterKeyChanged}, "
        "fieldChanged=${syncMergeContext.fieldChanged}, forceMerge=$forceMerge}",
      );

      // 在这种情况下需要更新远程文件
      if (syncMergeContext.masterKeyChanged ||
          syncMergeContext.fieldChanged ||
          forceMerge) {
        await remoteFile.write(syncMergeContext.data!);
        _logger.info("sync data write to remote file, done.");
      } else {
        // 没有变化
        _lastMergeContext = null;
      }
    } catch (e) {
      _lastError = e;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
