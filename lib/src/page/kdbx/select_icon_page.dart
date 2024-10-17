import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rpass/src/widget/extension_state.dart';

import '../../context/kdbx.dart';
import '../../kdbx/kdbx.dart';
import '../../util/file.dart';
import '../../widget/common.dart';

final _logger = Logger("page:select_icon_page");


class SelectIconPage extends StatefulWidget {
  const SelectIconPage({super.key});

  static const routeName = "/select_icon";

  @override
  State<SelectIconPage> createState() => _SelectIconPageState();
}

class _SelectIconPageState extends State<SelectIconPage> {
  void _onIconTap(KdbxIconWidgetData icon) {
    Navigator.of(context).pop(icon);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final kdbx = KdbxProvider.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("选择图标"),
      ),
      body: GridView.count(
        crossAxisCount: width ~/ 64,
        children: [
          ...kdbx.customIcons.map((item) {
            final kdbxIcon =
                KdbxIconWidgetData(icon: KdbxIcon.Key, customIcon: item);
            return InkWell(
              onTap: () => _onIconTap(kdbxIcon),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: KdbxIconWidget(
                  kdbxIcon: kdbxIcon,
                  size: 32,
                ),
              ),
            );
          }),
          const SizedBox(
            width: 64,
            height: 64,
          ),
          ...KdbxIcon.values.map(
            (item) {
              final kdbxIcon = KdbxIconWidgetData(icon: item);
              return InkWell(
                onTap: () => _onIconTap(kdbxIcon),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: KdbxIconWidget(
                    kdbxIcon: kdbxIcon,
                    size: 32,
                  ),
                ),
              );
            },
          ),
          const SizedBox(
            width: 64,
            height: 64,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final (_, bytes) = await SimpleFile.openFile(type: FileType.image);
            _onIconTap(KdbxIconWidgetData(
              icon: KdbxIcon.Key,
              customIcon: KdbxCustomIcon(uuid: KdbxUuid.random(), data: bytes),
            ));
          } catch (e) {
            if (e is! CancelException) {
              _logger.warning("read image file fail!", e);
              showError(e);
            }
          }
        },
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
