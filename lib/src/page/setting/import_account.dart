import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../component/toast.dart';
import '../../model/backup.dart';
import '../../store/index.dart';
import '../../util/file.dart';

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage({super.key, required this.store});

  static const routeName = "/import_account";

  final Store store;

  @override
  State<ImportAccountPage> createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage> {
  bool _isImporting = false;

  void _import() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final result = await SimpleFile.openText();
      await _verifyImport(result);
      showToast(context, "导入完成");
    } catch (e) {
      showToast(context, "导入异常: ${e.toString()}");
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<void> _verifyImport(String data) {
    final completer = Completer<void>();
    final accountsContrller = widget.store.accounts;
    Timer(const Duration(), () async {
      try {
        final object = json.decoder.convert(data);
        late Backup backup;
        try {
          backup = Backup.fromJson(object);
        } catch (e) {
          backup = await _denryptBackup(EncryptBackup.fromJson(object));
        }
        await accountsContrller.importBackupAccounts(backup);
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  Future<Backup> _denryptBackup(EncryptBackup encryptBackup) async {
    // TODO! 解密返回 Backup -> 处理导入冲突
    return const Backup(accounts: [], version: "0", buildNumber: "0");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("导入"),
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: !_isImporting
                  ? Container(
                      key: const ValueKey(1),
                      padding: const EdgeInsets.only(top: 12),
                      constraints: const BoxConstraints(minWidth: 180),
                      child: ElevatedButton(
                        onPressed: _import,
                        child: const Text("导入"),
                      ),
                    )
                  : Container(
                      key: const ValueKey(2),
                      margin: const EdgeInsets.only(top: 12),
                      width: 32,
                      height: 32,
                      child: const CircularProgressIndicator(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
