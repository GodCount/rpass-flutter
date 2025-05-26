import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../context/biometric.dart';
import '../../context/kdbx.dart';
import '../../page/route.dart';
import '../../rpass.dart';
import '../../kdbx/kdbx.dart';
import '../../remotes_fs/adapter/webdav.dart';
import '../../remotes_fs/remote_fs.dart';
import '../index.dart';

final _logger = Logger("store:sync_kdbx");

class SyncKdbxController with ChangeNotifier {
  WebdavConfig? _config;
  WebdavConfig? get config => _config;

  WebdavClient? _client;
  WebdavClient? get client => _client;

  Object? _lastError;
  Object? get lastError => _lastError;

  MergeContext? _lastMergeContext;
  MergeContext? get lastMergeContext => _lastMergeContext;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> setWebdavClient(
    BuildContext context,
    WebdavClient client,
  ) async {
    _config = client.config;
    _client = client;
    return sync(context);
  }

  Future<void> sync(
    BuildContext context, {
    bool forceMerge = false,
  }) async {
    try {
      _lastError = null;
      _lastMergeContext = null;

      _isSyncing = true;
      notifyListeners();

      final kdbx = KdbxProvider.of(context)!;

      if (kdbx.syncAccountEntry != null) {
        _config ??= WebdavConfig()..updateByKdbx(kdbx.syncAccountEntry!);
      }

      _client ??= await _config?.buildClient();

      if (_client == null) {
        _logger.info("Remote client is null, Unable to synchronize.");
        return;
      }

      final isKdbxExt = _client!.config.uri.endsWith(".kdbx");
      final localFile = Store.instance.localInfo.localKdbxFile;
      RemoteFile? remoteFile;

      try {
        remoteFile = await _client!.readFileInfo(
          isKdbxExt ? "" : RpassInfo.defaultSyncKdbxFileName,
        );
      } catch (e) {
        _logger.warning("remote read file info", e);
      }

      if (remoteFile != null && remoteFile.dir) {
        throw Exception(
          "${isKdbxExt ? _client!.config.uri : RpassInfo.defaultSyncKdbxFileName} is dir, Unable Sync File.",
        );
      } else if (remoteFile == null || remoteFile.size == 0) {
        if (!isKdbxExt) {
          // 尝试创建当前路径目录
          await _client!.mkdir(path: "");
        }

        await _client!.writeFile(
          path: isKdbxExt ? "" : RpassInfo.defaultSyncKdbxFileName,
          data: await localFile.readAsBytes(),
        );
        Store.instance.settings.setLastSyncTime(DateTime.now());
        return;
      }

      final remoteData = await remoteFile.readFile();
      Kdbx remoteKdbx;

      try {
        remoteKdbx = await Kdbx.loadBytesFromCredentials(
          data: remoteData,
          credentials: kdbx.credentials,
        );
      } catch (e) {
        _logger.warning("local credentials Unable open remote kdbx.", e);
        final result = await context.router.push(LoadExternalKdbxRoute(
          kdbxFile: remoteData,
        ));

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
        // TODO！上传因意外中断可能会导致远程数据丢失
        // 解决 先上传为一个临时文件
        // 成功后，删除原文件，再重命名临时文件为原文件
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
