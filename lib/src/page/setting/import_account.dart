import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/common.dart';
import '../../util/file.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';

final _logger = Logger("pagr:import_account");

class _ImportAccountArgs extends PageRouteArgs {
  _ImportAccountArgs({super.key});
}

class ImportAccountRoute extends PageRouteInfo<_ImportAccountArgs> {
  ImportAccountRoute({
    Key? key,
  }) : super(
          name,
          args: _ImportAccountArgs(key: key),
        );

  static const name = "ImportAccountRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ImportAccountArgs>(
        orElse: () => _ImportAccountArgs(),
      );
      return ImportAccountPage(key: args.key);
    },
  );
}

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage({super.key});

  @override
  State<ImportAccountPage> createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage>
    with SecondLevelPageAutoBack<ImportAccountPage> {
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
        _logger.warning("import csv file fail!", e);
        showError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
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
            title: Text(t.import_n_file("csv (chrome)")),
            onTap: () => _csvImport(FirefoxCsvAdapter()),
          ),
          ListTile(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(6.0),
                bottomRight: Radius.circular(6.0),
              ),
            ),
            title: Text(t.import_n_file("csv (firefox)")),
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
