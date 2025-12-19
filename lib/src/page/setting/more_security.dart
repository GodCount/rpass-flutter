import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../native/channel.dart';
import '../../native/platform/android.dart';
import '../../store/index.dart';
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
      final args = data.argsAs<_MoreSecurityArgs>(
        orElse: () => _MoreSecurityArgs(),
      );
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
  AutofillServiceStatus _autofillServiceStatus =
      AutofillServiceStatus.unsupported;

  @override
  void initState() {
    super.initState();
    NativeInstancePlatform.instance.autofillService
        .status()
        .then((value) => setState(() => _autofillServiceStatus = value));
  }

  void _setLockDelay() {
    final t = I18n.of(context)!;

    final settings = Store.instance.settings;

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
        trailing: settings.lockDelay == null ? const Icon(Icons.check) : null,
        onTap: autoSavePop(null),
      ),
      ListTile(
        title: Text(t.seconds(30)),
        trailing: settings.lockDelay == const Duration(seconds: 30)
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(const Duration(seconds: 30)),
      ),
      ListTile(
        title: Text(t.minutes(3)),
        trailing: settings.lockDelay == const Duration(minutes: 3)
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(const Duration(minutes: 3)),
      ),
      ListTile(
        title: Text(t.minutes(5)),
        trailing: settings.lockDelay == const Duration(minutes: 5)
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(const Duration(minutes: 5)),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final store = Store.instance;

    final lockDelay = store.settings.lockDelay;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
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
                !store.settings.enableRecordKeyFilePath,
              );
              setState(() {});
            },
            title: Text(t.record_key_file_path),
            trailing: store.settings.enableRecordKeyFilePath
                ? const Icon(Icons.check)
                : null,
          ),
          if (Platform.isAndroid) ...[
            ListTile(
              enabled:
                  _autofillServiceStatus != AutofillServiceStatus.unsupported,
              onTap: () async {
                if (_autofillServiceStatus == AutofillServiceStatus.enabled) {
                  await NativeInstancePlatform.instance.autofillService
                      .disabled();
                  _autofillServiceStatus = AutofillServiceStatus.disabled;
                } else {
                  final result = await NativeInstancePlatform
                      .instance.autofillService
                      .enabled();
                  _autofillServiceStatus = result
                      ? AutofillServiceStatus.enabled
                      : AutofillServiceStatus.disabled;
                }
                setState(() {});
              },
              title: Text(t.enable_auto_fill_service),
              trailing: _autofillServiceStatus == AutofillServiceStatus.enabled
                  ? const Icon(Icons.check)
                  : null,
            ),
            ListTile(
              enabled: _autofillServiceStatus == AutofillServiceStatus.enabled,
              onTap: () async {
                await store.settings.setManualSelectFillItem(
                  !store.settings.manualSelectFillItem,
                );
                setState(() {});
              },
              title: Text(t.manual_select_fill_item),
              subtitle: Text(t.manual_select_fill_item_subtitle),
              trailing: store.settings.manualSelectFillItem
                  ? const Icon(Icons.check)
                  : null,
            ),
          ]
        ],
      ),
    );
  }
}
