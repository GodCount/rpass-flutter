import 'dart:async';

import 'package:flutter/material.dart';

import '../util/common.dart';
import 'kdbx.dart';

class KdbxDetectionController with ChangeNotifier {
  KdbxDetectionController(this.kdbx);

  Kdbx kdbx;

  // 弱密码列表
  List<KdbxEntry> _weakPassList = [];
  List<KdbxEntry> get weakPassList => List.unmodifiable(_weakPassList);

  // 过期的密码列表
  List<KdbxEntry> _expiredPassList = [];
  List<KdbxEntry> get expiredPassList => List.unmodifiable(_expiredPassList);

  // 附件文件引用列表
  Map<KdbxBinary, List<KdbxEntry>> _binaryList = {};
  Map<KdbxBinary, List<KdbxEntry>> get binaryList =>
      Map.unmodifiable(_binaryList);

  KdbxEntry? _currentEntry;
  KdbxEntry? get currentEntry => _currentEntry;

  Future<void>? _future;

  bool _canceled = false;
  bool get isDetecting => _future != null;

  bool _isWeakPass(String pass) {
    return passwordEntropy(pass.length, passCharSetLength(pass)) < 32;
  }

  Future<void> _detect() async {
    _clean();

    for (final item in kdbx.totalEntry) {
      _currentEntry = item;
      if (_canceled) break;

      notifyListeners();

      if (_isWeakPass(item.getNonNullString(KdbxKeyCommon.PASSWORD))) {
        _weakPassList.add(item);
      }

      if (item.isExpiry()) {
        _expiredPassList.add(item);
      }

      if (item.binaryEntries.isNotEmpty) {
        for (final entry in item.binaryEntries) {
          _binaryList[entry.value] ??= [];
          _binaryList[entry.value]!.add(item);
        }
      }
    }

    _currentEntry = null;
  }

  void _clean() {
    _weakPassList = [];
    _expiredPassList = [];
    _binaryList = {};
    _currentEntry = null;
    _future = null;
    _canceled = false;
  }

  Future<void> detect() async {
    _future ??= _detect();
    await _future!;
    _future = null;
    notifyListeners();
  }

  Future<void> cancel() {
    assert(!_canceled && _future != null, "detect not runing");
    _canceled = true;
    return _future!;
  }

  @override
  void dispose() {
    super.dispose();
    _clean();
  }
}
