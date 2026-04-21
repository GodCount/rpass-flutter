import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:common_native_channel/common_native_channel.dart';
import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../native/channel.dart';
import '../../native/platform/android.dart';
import '../../store/index.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
import '../../widget/kdbx_icon.dart';
import '../route.dart';

class _MoreSecurityArgs extends PageRouteArgs {
  _MoreSecurityArgs({super.key});
}

class MoreSecurityRoute extends PageRouteInfo<_MoreSecurityArgs> {
  MoreSecurityRoute({Key? key})
    : super(name, args: _MoreSecurityArgs(key: key));

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
    NativeInstancePlatform.instance.autofillService.status().then(
      (value) => setState(() => _autofillServiceStatus = value),
    );
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

    showBottomSheetList(
      title: t.lock,
      children: [
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
        ),
      ],
    );
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
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
                      .instance
                      .autofillService
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
              onTap: () {
                _AutoFillSetting.show(context);
              },
              title: Text(t.autofill_setting),
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoFillSetting extends StatefulWidget {
  const _AutoFillSetting();

  static Future<void> show(BuildContext context) async {
    await showBottomSheetView(
      context: context,
      builder: (context) {
        return const _AutoFillSetting();
      },
    );
  }

  @override
  State<_AutoFillSetting> createState() => _AutoFillSettingState();
}

class _AutoFillSettingState extends State<_AutoFillSetting> {
  void showAppBlacklistDialog() {
    _AutoFillAppIdBlacklist.openDialog(context);
  }

  void showDomainBlacklistDialog() {
    _AutoFillDomainBlacklist.openDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final store = Store.instance;

    return Column(
      mainAxisSize: .min,
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          primary: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(t.autofill_setting),
          titleTextStyle: Theme.of(context).textTheme.titleLarge,
          actionsPadding: const EdgeInsets.only(right: 16),
        ),
        ListView(
          shrinkWrap: true,
          children: [
            ListTile(
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
            ListTile(
              onTap: showAppBlacklistDialog,
              title: Text(t.app_blacklist),
              subtitle: Text(t.autofill_app_blacklist_message),
            ),
            ListTile(
              onTap: showDomainBlacklistDialog,
              title: Text(t.domain_blacklist),
              subtitle: Text(t.autofill_domain_blacklist_message),
            ),
          ],
        ),
      ],
    );
  }
}

class _AutoFillAppIdBlacklist extends StatefulWidget {
  const _AutoFillAppIdBlacklist();

  static Future<void> openDialog(BuildContext context) async {
    await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return _AutoFillAppIdBlacklist();
      },
    );
  }

  @override
  State<_AutoFillAppIdBlacklist> createState() =>
      _AutoFillAppIdBlacklistState();
}

class _AutoFillAppIdBlacklistState extends State<_AutoFillAppIdBlacklist> {
  Future<List<AppInfo>>? _future;

  @override
  void initState() {
    super.initState();
    setState(() {
      _future = installedApps.getInstalledApps();
    });
  }

  AppInfo? _getAppInfo(List<AppInfo> list, String packageName) {
    try {
      return list.lastWhere((it) => it.packageName == packageName);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(t.app_blacklist)),
          IconButton(
            onPressed: () async {
              final packageNames = await context.router.push(
                SelectAutoFillAppRoute(
                  packageNames: Store.instance.settings.autoFillAppIdBlacklist,
                ),
              );

              if (packageNames != null && packageNames is List<String>) {
                Store.instance.settings.setAutoFillAppIdBlacklist(packageNames);
                setState(() {});
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      contentPadding: EdgeInsets.only(
        top: Theme.of(context).useMaterial3 ? 16.0 : 20.0,
        right: 0,
        bottom: 24.0,
        left: 0,
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(minHeight: 200, maxWidth: 312),
        child: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: snapshot.hasError
                      ? Text("${snapshot.error}")
                      : const CircularProgressIndicator(),
                ),
              );
            }
            final autoFillAppIdBlacklist =
                Store.instance.settings.autoFillAppIdBlacklist;

            if (autoFillAppIdBlacklist.isEmpty) {
              return SizedBox(height: 200, child: Center(child: Text(t.empty)));
            }

            final data = snapshot.data ?? [];

            return ListView.builder(
              shrinkWrap: true,
              itemCount: autoFillAppIdBlacklist.length,
              itemBuilder: (context, index) {
                final packageName = autoFillAppIdBlacklist[index];
                final item = _getAppInfo(data, packageName);
                return ListTile(
                  leading: item != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(6),
                          ),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: ImageFileString(
                              item.icon,
                              error: const Icon(
                                Icons.android_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        )
                      : Icon(Icons.android, size: 32),
                  title: Text(item?.name ?? packageName),
                  subtitle: item != null ? Text(item.packageName) : null,
                  trailing: IconButton(
                    onPressed: () {
                      Store.instance.settings.setAutoFillAppIdBlacklist(
                        autoFillAppIdBlacklist
                            .where((it) => it != packageName)
                            .toList(),
                      );
                      setState(() {});
                    },
                    icon: Icon(Icons.delete),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AutoFillDomainBlacklist extends StatefulWidget {
  const _AutoFillDomainBlacklist();

  static Future<void> openDialog(BuildContext context) async {
    await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return _AutoFillDomainBlacklist();
      },
    );
  }

  @override
  State<_AutoFillDomainBlacklist> createState() =>
      _AutoFillDomainBlacklistState();
}

class _AutoFillDomainBlacklistState extends State<_AutoFillDomainBlacklist> {
  void _addDomain() async {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context).kdbx!;

    final autoFillDomainBlacklist =
        Store.instance.settings.autoFillDomainBlacklist;

    final result = await InputDialog.openDialog(
      context,
      title: t.add,
      label: t.domain,
      promptItmes: kdbx.fieldStatistic.urls
          .where((item) => !autoFillDomainBlacklist.contains(item))
          .toList(),
      limitItems: autoFillDomainBlacklist,
    );
    if (result != null && result is String) {
      Store.instance.settings.setAutoFillDomainBlacklist([
        result,
        ...autoFillDomainBlacklist,
      ]);

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final autoFillDomainBlacklist =
        Store.instance.settings.autoFillDomainBlacklist;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(t.domain_blacklist)),
          IconButton(onPressed: _addDomain, icon: const Icon(Icons.add)),
        ],
      ),
      contentPadding: EdgeInsets.only(
        top: Theme.of(context).useMaterial3 ? 16.0 : 20.0,
        right: 0,
        bottom: 24.0,
        left: 0,
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(minHeight: 200, maxWidth: 312),
        child: autoFillDomainBlacklist.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: autoFillDomainBlacklist.length,
                itemBuilder: (context, index) {
                  final item = autoFillDomainBlacklist[index];
                  return ListTile(
                    leading: KdbxIconWidget(
                      size: 24,
                      kdbxIcon: KdbxIconWidgetData(icon: .World, domain: item),
                    ),
                    title: Text(item),
                    trailing: IconButton(
                      onPressed: () {
                        Store.instance.settings.setAutoFillDomainBlacklist(
                          autoFillDomainBlacklist
                              .where((it) => it != item)
                              .toList(),
                        );
                        setState(() {});
                      },
                      icon: Icon(Icons.delete),
                    ),
                  );
                },
              )
            : SizedBox(height: 200, child: Center(child: Text(t.empty))),
      ),
    );
  }
}
