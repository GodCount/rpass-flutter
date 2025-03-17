import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rpass/src/kdbx/kdbx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../context/biometric.dart';
import '../../context/kdbx.dart';
import '../../context/store.dart';
import '../../i18n.dart';
import '../../rpass.dart';
import '../../widget/extension_state.dart';
import '../../widget/shake_widget.dart';
import '../page.dart';

final _logger = Logger("page:settings");

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.0), bottomRight: Radius.circular(6.0)),
    );

    final t = I18n.of(context)!;

    final store = StoreProvider.of(context);
    final biometric = Biometric.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.setting),
      ),
      body: ListView(
        padding: const EdgeInsets.all(6),
        children: [
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.color_lens),
                  ),
                  Text(t.theme, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: Text(t.system),
              trailing: store.settings.themeMode == ThemeMode.system
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                store.settings.setThemeMode(ThemeMode.system);
              },
            ),
            ListTile(
              title: Text(t.light),
              trailing: store.settings.themeMode == ThemeMode.light
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                store.settings.setThemeMode(ThemeMode.light);
              },
            ),
            ListTile(
              shape: shape,
              title: Text(t.dark),
              trailing: store.settings.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                store.settings.setThemeMode(ThemeMode.dark);
              },
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.view_in_ar_rounded),
                  ),
                  Text(
                    t.pass_lib,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: Text(t.recycle_bin),
              trailing: const Icon(Icons.recycling_rounded),
              onTap: () {
                Navigator.of(context).pushNamed(RecycleBinPage.routeName);
              },
            ),
            // TODO! 上游 kdbx.dart 还没实现
            // ListTile(
            //   shape: shape,
            //   title: const Text("更多设置"),
            //   trailing: const Icon(Icons.chevron_right_rounded),
            //   onTap: () {
            //     Navigator.of(context).pushNamed(KdbxSettingPage.routeName);
            //   },
            // ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.translate),
                  ),
                  Text(t.language,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: Text(
                  store.settings.locale != null ? t.locale_name : t.system),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).pushNamed(ChangeLocalePage.routeName);
              },
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.security),
                  ),
                  Text(t.security,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            if (biometric.isSupport)
              ListTile(
                title: Text(t.biometric),
                trailing: store.settings.enableBiometric
                    ? const Icon(Icons.check)
                    : null,
                onTap: () async {
                  try {
                    final kdbx = KdbxProvider.of(context)!;

                    final enableBiometric = !store.settings.enableBiometric;
                    await biometric.updateCredentials(
                      context,
                      enableBiometric ? kdbx.credentials.getHash() : null,
                    );
                    store.settings.seEnableBiometric(enableBiometric);
                    _logger.finest("biometric status is $enableBiometric");
                  } catch (e, s) {
                    if (e is AuthException &&
                        (e.code == AuthExceptionCode.userCanceled ||
                            e.code == AuthExceptionCode.canceled ||
                            e.code == AuthExceptionCode.timeout)) {
                      return;
                    }
                    _logger.severe("set biometric exception!", e, s);
                    showError(e);
                  } finally {
                    setState(() {});
                  }
                },
              ),
            ListTile(
              title: Text(t.modify_password),
              onTap: () {
                Navigator.of(context).pushNamed(ModifyPasswordPage.routeName);
              } ,
            ),
            ListTile(
              shape: shape,
              title: Text(t.more_settings),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).pushNamed(MoreSecurityPage.routeName);
              },
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.import_export),
                  ),
                  Text(t.backup, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: Text(t.import),
              onTap: () {
                Navigator.of(context).pushNamed(ImportAccountPage.routeName);
              },
            ),
            ListTile(
              shape: shape,
              title: Text(t.export),
              onTap: () {
                Navigator.of(context).pushNamed(ExportAccountPage.routeName);
              },
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.touch_app),
                  ),
                  Text(t.info, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: Text(t.about),
              onTap: () {
                showAboutDialog(
                    context: context,
                    applicationName: RpassInfo.appName,
                    applicationVersion: RpassInfo.version,
                    applicationIcon: const Image(
                      image: AssetImage('assets/icons/logo.png'),
                      width: 72,
                      height: 72,
                    ),
                    applicationLegalese: t.app_description,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OverflowBar(
                          spacing: 8,
                          alignment: MainAxisAlignment.end,
                          overflowAlignment: OverflowBarAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async => await launchUrl(
                                  Uri.parse(
                                      "https://github.com/GodCount/rpass-flutter"),
                                  mode: LaunchMode.externalApplication),
                              child: Text(t.source_code_location("Github")),
                            ),
                            TextButton(
                              onPressed: () async => await launchUrl(
                                  Uri.parse(
                                      "https://gitee.com/do_yzr/rpass-flutter"),
                                  mode: LaunchMode.externalApplication),
                              child: Text(t.source_code_location("Gitee")),
                            ),
                          ],
                        ),
                      )
                    ]);
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _cardColumn(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6.0)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
