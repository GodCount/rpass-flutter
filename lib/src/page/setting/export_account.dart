import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../rpass.dart';
import '../../util/common.dart';
import '../../util/file.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';

final _logger = Logger("page:export_account");

class _ExportAccountArgs extends PageRouteArgs {
  _ExportAccountArgs({super.key});
}

class ExportAccountRoute extends PageRouteInfo<_ExportAccountArgs> {
  ExportAccountRoute({
    Key? key,
  }) : super(
          name,
          args: _ExportAccountArgs(key: key),
        );

  static const name = "ExportAccountRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ExportAccountArgs>();
      return ExportAccountPage(key: args.key);
    },
  );
}

class ExportAccountPage extends StatefulWidget {
  const ExportAccountPage({super.key});

  @override
  State<ExportAccountPage> createState() => _ExportAccountPageState();
}

class _ExportAccountPageState extends State<ExportAccountPage>
    with SecondLevelPageAutoBack<ExportAccountPage> {
  void _exportKdbxFile() async {
    final kdbx = KdbxProvider.of(context)!;
    try {
      final filepath = await SimpleFile.saveFile(
        data: await kdbx.getKdbxFileBytes(),
        filename: "${RpassInfo.appName}.kdbx",
      );
      showToast(I18n.of(context)!.export_done_location(filepath));
    } catch (e) {
      if (e is! CancelException) {
        _logger.warning("export kdbx file fail!", e);
        showError(e);
      }
    }
  }

  void _otherExportAlert(FormatTransform adapter) async {
    final t = I18n.of(context)!;

    if (await showConfirmDialog(
      title: t.warn,
      message: t.plaintext_export_warn,
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
        showToast(t.export_done_location(filepath));
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
        leading: autoBack(),
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
            title: Text(t.export_n_file("kdbx")),
            onTap: _exportKdbxFile,
          ),
          ListTile(
            title: Text(t.export_n_file("csv (chrome)")),
            onTap: () => _otherExportAlert(ChromeCsvAdapter()),
          ),
          ListTile(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(6.0),
                bottomRight: Radius.circular(6.0),
              ),
            ),
            title: Text(t.export_n_file("csv (firefox)")),
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
