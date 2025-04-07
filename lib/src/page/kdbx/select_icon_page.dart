import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rpass/src/widget/extension_state.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/file.dart';
import '../../util/route.dart';
import '../../widget/common.dart';

final _logger = Logger("page:select_icon_page");

class _SelectIconArgs extends PageRouteArgs {
  _SelectIconArgs({super.key});
}

class SelectIconRoute extends PageRouteInfo<_SelectIconArgs> {
  SelectIconRoute({
    Key? key,
  }) : super(
          name,
          args: _SelectIconArgs(key: key),
        );

  static const name = "SelectIconRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_SelectIconArgs>();
      return SelectIconPage(key: args.key);
    },
  );
}

class SelectIconPage extends StatefulWidget {
  const SelectIconPage({super.key});

  @override
  State<SelectIconPage> createState() => _SelectIconPageState();
}

class _SelectIconPageState extends State<SelectIconPage> {
  void _onIconTap(KdbxIconWidgetData icon) {
    context.router.pop(icon);
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final kdbx = KdbxProvider.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.select_icon),
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
        heroTag: const ValueKey("select_icon_float"),
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
