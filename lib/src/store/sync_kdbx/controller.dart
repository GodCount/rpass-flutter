import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

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
    // 通过 lastSaveTime 判断是否需要合并
    // forceMerge is true 跳过 lastSaveTime 判断
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

      final lastSaveEqual = kdbx.lastSaveTime != null &&
          kdbx.lastSaveTime == remoteKdbx.lastSaveTime;

      if (!forceMerge && lastSaveEqual) {
        _logger.info("last save uuid equal skip merge");
        return;
      }

      if (forceMerge) {
        _logger.info("force merge, lastSaveTime: $lastSaveEqual");
      }

      _lastMergeContext = kdbx.merge(remoteKdbx);

      // 密钥不相等
      // 如果远程的比本地的新，则覆盖本地的
      if (kdbx.credentials != remoteKdbx.credentials) {
        _logger.info("credentials not equal!");

        // TODO! 更新本地密钥
        // 更新指纹识别

        // if (remoteKdbx.lastSaveTime != null &&
        //     kdbx.lastSaveTime != null &&
        //     remoteKdbx.lastSaveTime!.isAfter(kdbx.lastSaveTime!)) {
        //   _logger.info("remote credentials override local");
        //   kdbx.modifyCredentials(remoteKdbx.credentials);
        // }
      }

      final newlyData = await kdbx.save();

      _logger.info("merge save in local.");

      await remoteFile.write(newlyData);

      _logger.info("sync data write to remote file, done.");
    } catch (e) {
      _lastError = e;
      // rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
