import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:logging/logging.dart';
import 'package:remote_fs/remote_fs.dart';

import '../../context/biometric.dart';
import '../../kdbx/kdbx.dart';
import '../../page/route.dart';
import '../../rpass.dart';
import '../../remotes_fs/remote_fs.dart';
import '../../util/common.dart';
import '../index.dart';

final _logger = Logger("store:kdbx");

const SYNC_ACCOUNT_UUID = "sync_account_uuid";

mixin KdbxProviderListener {
  void onKdbxChanged(Kdbx? kdbx) {}

  void onKdbxSaved() {}

  void onSelectedKdbxEntryChanged(String? kdbxEntry) {}
}

class KdbxController with SimpleObserverListener<KdbxProviderListener> {
  Kdbx? _kdbx;
  Kdbx? get kdbx => _kdbx;

  late final syncController = SyncKdbxController(this);

  FieldSummary? _fieldSummary;
  FieldSummary? get fieldSummary => _fieldSummary;

  Meta? _meta;
  Meta? get meta => _meta;

  Map<String, GroupData>? _groups;

  List<GroupData>? _noRecyclebinGroups;

  List<GroupData> get groups => List.unmodifiable(_noRecyclebinGroups ?? []);

  String? _selectedKdbxEntry;
  String? get selectedKdbxEntry => _selectedKdbxEntry;

  String? _syncAccountUuid;
  String? get syncAccountUuid => _syncAccountUuid;

  void _kdbxEventCallback(KdbxEvent event) async {
    switch (event) {
      case KdbxEvent_Saved():
        await _getSummary();
        emit((listener) => listener.onKdbxSaved());
      case KdbxEvent_None():
        throw UnimplementedError();
    }
  }

  Future<void> _getSummary() async {
    final summary = await _kdbx!.summary();
    _fieldSummary = summary.$1;
    _meta = summary.$2;
    _groups = summary.$3;
    _noRecyclebinGroups = _groups!.values
        .where((item) => !isInRecycleBin(item.id))
        .toList();
  }

  Future<void> _getSyncUuid() async {
    if (_meta?.customData.contains(SYNC_ACCOUNT_UUID) == true) {
      final customDataItem = await kdbx!.getCustomData(key: SYNC_ACCOUNT_UUID);
      if (customDataItem?.value is CustomDataValue_String) {
        _syncAccountUuid = customDataItem!.value!.field0 as String;
      }
    }
  }

  Future<void> setKdbx(Kdbx? kdbx) async {
    _kdbx?.bindEventCallback(callback: (_) => {});
    _kdbx?.dispose();
    _kdbx = kdbx;
    _selectedKdbxEntry = null;

    if (kdbx != null) {
      kdbx.bindEventCallback(callback: _kdbxEventCallback);

      await _getSummary();
      await _getSyncUuid();
    }

    emit((listener) {
      listener.onKdbxChanged(kdbx);
      listener.onSelectedKdbxEntryChanged(null);
    });
  }

  void setSelectedKdbxEntry(String? kdbxEntry) {
    if (kdbxEntry == selectedKdbxEntry) return;

    _selectedKdbxEntry = kdbxEntry;
    emit((listener) => listener.onSelectedKdbxEntryChanged(kdbxEntry));
  }

  GroupData? getGroup(String id) {
    return _groups?[id];
  }

  GroupData rootGroup() {
    return groups.firstWhere((item) => item.parent == null);
  }

  bool isInRecycleBin(String id) {
    final recycleId = meta?.recyclebinUuid;

    if (id == recycleId) return true;

    if (recycleId == null || _groups?[recycleId] == null) return false;

    final parent = _groups?[id]?.parent;
    return parent != null ? isInRecycleBin(parent) : false;
  }

  String getAutoTypeSequence(String id) {
    final parent = _groups?[id]?.parent;

    return _groups?[id]?.defaultAutotypeSequence ??
        (parent != null
            ? getAutoTypeSequence(parent)
            : defaultAutoTypeSequence);
  }

  Future<EntryData?> getSyncEntryData() async {
    if (syncAccountUuid == null) return null;
    try {
      return kdbx!.getEntry(id: syncAccountUuid!);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _kdbx?.dispose();
    _kdbx = _groups = _fieldSummary = _selectedKdbxEntry = null;
    removeAllListener();
  }
}

class SyncKdbxController with ChangeNotifier {
  SyncKdbxController(this._kdbxController);

  final KdbxController _kdbxController;

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

      final kdbx = _kdbxController.kdbx!;

      if (_config == null) {
        final entry = await _kdbxController.getSyncEntryData();
        _config = entry != null
            ? RemoteFileKdbxEntryField.fromKdbx(entry)
            : null;
      }

      if (_config == null) {
        _logger.info("Remote config is null, Unable to synchronize.");
        return;
      }

      RemoteFile remoteFile = await _config!.open();
      final localFile = Store.localInfo.localKdbxFile;

      if (!await remoteFile.exists()) {
        remoteFile.write(await localFile.readAsBytes());
        Store.settings.setLastSyncTime(DateTime.now());
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

      Store.settings.setLastSyncTime(DateTime.now());

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
            Store.settings.seEnableBiometric(false);
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
