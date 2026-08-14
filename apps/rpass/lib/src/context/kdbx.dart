import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';

import '../kdbx/kdbx.dart';
import '../util/common.dart';

const SYNC_ACCOUNT_UUID = "sync_account_uuid";

class KdbxProvider extends StatefulWidget {
  const KdbxProvider({super.key, required this.child});

  final Widget child;

  static KdbxProviderState _ofState(BuildContext context) {
    KdbxProviderState? kdbxProvider;
    if (context is StatefulElement && context.state is KdbxProviderState) {
      kdbxProvider = context.state as KdbxProviderState;
    }

    kdbxProvider =
        kdbxProvider ?? context.findAncestorStateOfType<KdbxProviderState>();

    assert(() {
      if (kdbxProvider == null) {
        throw FlutterError(
          'KdbxProvider operation requested with a context that does not include a KdbxProvider.\n'
          'The context used to kdbx from the KdbxProvider must be that of a '
          'widget that is a descendant of a KdbxProvider widget.',
        );
      }
      return true;
    }());

    return kdbxProvider!;
  }

  static KdbxProviderState of(BuildContext context) {
    return _ofState(context);
  }

  @override
  State<KdbxProvider> createState() => KdbxProviderState();
}

mixin KdbxProviderListener {
  void onKdbxChanged(Kdbx? kdbx) {}

  void onKdbxSaved() {}

  void onSelectedKdbxEntryChanged(String? kdbxEntry) {}
}

class KdbxProviderState extends State<KdbxProvider>
    with SimpleObserverListener<KdbxProviderListener> {
  Kdbx? _kdbx;
  Kdbx? get kdbx => _kdbx;

  FieldSummary? _fieldSummary;
  FieldSummary? get fieldSummary => _fieldSummary;

  Meta? _meta;
  Meta? get meta => _meta;

  Map<String, GroupData>? _groups;
  List<GroupData> get groups => List.unmodifiable(_groups?.values ?? []);

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

  @override
  void dispose() {
    super.dispose();
    _kdbx?.dispose();
    _kdbx = _groups = _fieldSummary = _selectedKdbxEntry = null;
    removeAllListener();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

extension FieldSummaryCommon on FieldSummary {
  Set<String> getStatistic(String kdbxKey) {
    switch (kdbxKey) {
      case KdbxKeyCommon.URL:
      case KdbxKeyURLS.URL1:
      case KdbxKeyURLS.URL2:
      case KdbxKeyURLS.URL3:
      case KdbxKeyURLS.URL4:
      case KdbxKeyURLS.URL5:
        return urls;
      case KdbxKeyCommon.USER_NAME:
        return userNames;
      case KdbxKeyCommon.EMAIL:
        return emails;
      case KdbxKeySpecial.TAGS:
        return tags;
      case "CustomFields":
        return customFields;
      case "CustomIcons":
        return customIcons.keys.toSet();
    }
    return {};
  }
}
