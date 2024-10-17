import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../rpass.dart';
import '../../util/common.dart';
import '../../util/file.dart';
import '../../widget/extension_state.dart';

final _logger = Logger("page:export_account");

class ExportAccountPage extends StatefulWidget {
  const ExportAccountPage({super.key});

  static const routeName = "/export_account";

  @override
  ExportAccountPageState createState() => ExportAccountPageState();
}

class ExportAccountPageState extends State<ExportAccountPage> {
  void _exportKdbxFile() async {
    final kdbx = KdbxProvider.of(context)!;
    try {
      final filepath = await SimpleFile.saveFile(
        data: await kdbx.getKdbxFileBytes(),
        filename: "${RpassInfo.appName}.kdbx",
      );
      showToast(filepath);
    } catch (e) {
      if (e is! CancelException) {
        _logger.warning("export kdbx file fail!", e);
        showError(e);
      }
    }
  }

  void _otherExportAlert(FormatTransform adapter) async {
    if (await showConfirmDialog(
      title: "警告",
      message: "确认明文导出数据?\n注意导出的数据只包含对应的关键字段.",
    )) {
      final kdbx = KdbxProvider.of(context)!;
      try {
        final result = jsonToCsv(adapter.export(
          kdbx.totalEntry.map((item) => item.toPlainMapEntry()).toList(),
        ));
        final filepath = await SimpleFile.saveText(
          data: result,
          filename: "${RpassInfo.appName}_${adapter.name}.csv",
        );
        showToast(filepath);
      } catch (e) {
        if (e is! CancelException) {
          _logger.warning("export file file fail!", e);
          showError(e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.export),
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
            title: Text("导出 kdbx 文件"),
            onTap: _exportKdbxFile,
          ),
          ListTile(
            title: Text("导出 csv 文件(chrome)"),
            onTap: () => _otherExportAlert(ChromeCsvAdapter()),
          ),
          ListTile(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(6.0),
                bottomRight: Radius.circular(6.0),
              ),
            ),
            title: Text("导出 csv 文件(firefox)"),
            onTap: () => _otherExportAlert(FirefoxCsvAdapter()),
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
