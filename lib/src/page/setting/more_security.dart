import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../context/store.dart';
import '../../i18n.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';

class _MoreSecurityArgs extends PageRouteArgs {
  _MoreSecurityArgs({super.key});
}

class MoreSecurityRoute extends PageRouteInfo<_MoreSecurityArgs> {
  MoreSecurityRoute({
    Key? key,
  }) : super(
          name,
          args: _MoreSecurityArgs(key: key),
        );

  static const name = "MoreSecurityRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_MoreSecurityArgs>();
      return MoreSecurityPage(key: args.key);
    },
  );
}

class MoreSecurityPage extends StatefulWidget {
  const MoreSecurityPage({super.key});

  @override
  State<MoreSecurityPage> createState() => _MoreSecurityPageState();
}

class _MoreSecurityPageState extends State<MoreSecurityPage>
    with SecondLevelPageAutoBack<MoreSecurityPage> {
  void _setLockDelay() {
    final t = I18n.of(context)!;

    final settings = StoreProvider.of(context).settings;

    GestureTapCallback? autoSavePop(Duration? delay) {
      return () {
        settings.setLockDelay(delay);
        context.router.pop();
        setState(() {});
      };
    }

    showBottomSheetList(title: t.lock, children: [
      ListTile(
        title: Text(t.never),
        enabled: settings.lockDelay != null,
        onTap: autoSavePop(null),
      ),
      ListTile(
        title: Text(t.seconds(30)),
        enabled: settings.lockDelay != const Duration(seconds: 30),
        onTap: autoSavePop(const Duration(seconds: 30)),
      ),
      ListTile(
        title: Text(t.minutes(3)),
        enabled: settings.lockDelay != const Duration(minutes: 3),
        onTap: autoSavePop(const Duration(minutes: 3)),
      ),
      ListTile(
        title: Text(t.minutes(5)),
        enabled: settings.lockDelay != const Duration(minutes: 5),
        onTap: autoSavePop(const Duration(minutes: 5)),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final store = StoreProvider.of(context);

    final lockDelay = store.settings.lockDelay;

    return Scaffold(
      appBar: AppBar(
        leading: autoBack(),
        title: Text(t.security),
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: _setLockDelay,
            title: Text(t.lock),
            trailing: Text(
              lockDelay == null
                  ? t.never
                  : lockDelay.inSeconds < 60
                      ? t.seconds(lockDelay.inSeconds)
                      : t.minutes(lockDelay.inMinutes),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            onTap: () async {
              await store.settings.settEnableRecordKeyFilePath(
                  !store.settings.enableRecordKeyFilePath);
              setState(() {});
            },
            title: Text(t.record_key_file_path),
            trailing: store.settings.enableRecordKeyFilePath
                ? const Icon(Icons.check)
                : null,
          ),
        ],
      ),
    );
  }
}
