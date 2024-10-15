import 'package:flutter/material.dart';
import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/common.dart';
import '../../util/file.dart';
import '../../widget/extension_state.dart';

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage({super.key});

  static const routeName = "/import_account";

  @override
  State<ImportAccountPage> createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage> {
  void _csvImport(FormatTransform adapter) async {
    final t = I18n.of(context)!;

    try {
      final kdbx = KdbxProvider.of(context)!;
      final result = await SimpleFile.openText(allowedExtensions: ["csv"]);
      final list = adapter.import(csvToJson(result, shouldParseNumbers: false));
      kdbx.import(list);
      if (await kdbxSave(kdbx)) {
        showToast("${t.import_done} ${list.length}");
      }
    } catch (e) {
      if (e is! CancelException) {
        showToast(t.import_throw(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.import),
      ),
      body: Center(
        child: _cardColumn([
          ListTile(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6.0),
                topRight: Radius.circular(6.0),
              ),
            ),
            title: Text("导入 csv 文件(chrome)"),
            onTap: () => _csvImport(FirefoxCsvAdapter()),
          ),
          ListTile(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(6.0),
                bottomRight: Radius.circular(6.0),
              ),
            ),
            title: Text("导入 csv 文件(firefox)"),
            onTap: () => _csvImport(FirefoxCsvAdapter()),
          ),
        ]),
      ),
    );
  }

  Widget _cardColumn(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
