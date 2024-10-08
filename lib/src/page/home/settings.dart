import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpass/src/kdbx/kdbx.dart';

import '../../context/biometric.dart';
import '../../context/kdbx.dart';
import '../../context/store.dart';
import '../../i18n.dart';
import '../../util/file.dart';
import '../../widget/common.dart';
import '../page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin, CommonWidgetUtil {
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
                    "密码库",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: const Text("回收站"),
              trailing: const Icon(Icons.recycling_rounded),
              onTap: () {
                Navigator.of(context).pushNamed(RecycleBinPage.routeName);
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
                  } on AuthException catch (e) {
                    if (e.code == AuthExceptionCode.userCanceled ||
                        e.code == AuthExceptionCode.canceled ||
                        e.code == AuthExceptionCode.timeout) {
                      return;
                    }
                    rethrow;
                  } catch (e) {
                    showToast(t.biometric_throw(e.toString()));
                  }
                },
              ),
            ListTile(
              title: Text(t.modify_password),
              onTap: _modifyPassword,
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
                final kdbx = KdbxProvider.of(context)!;
                SimpleFile.saveText(
                  data: kdbx.kdbxFile.body.toXml().toXmlString(),
                  filename: "test.xml",
                );
                // Navigator.of(context).pushNamed(ExportAccountPage.routeName);
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
                Navigator.of(context).pushNamed(AboutPage.routeName);
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

  void _modifyPassword() {
    final GlobalKey<FormState> formState = GlobalKey<FormState>();
    String newPassword = "";

    final t = I18n.of(context)!;

    void onSetPassword() async {
      if (formState.currentState!.validate()) {
        try {
          final biometric = Biometric.of(context);
          final kdbx = KdbxProvider.of(context)!;

          final oldCredentials = kdbx.credentials;
          final credentials = kdbx.createCredentials(newPassword);

          if (biometric.enable) {
            try {
              await biometric.updateCredentials(
                context,
                credentials.getHash(),
              );
            } on AuthException catch (e) {
              if (e.code == AuthExceptionCode.userCanceled ||
                  e.code == AuthExceptionCode.canceled ||
                  e.code == AuthExceptionCode.timeout) {
                return;
              }
              rethrow;
            } catch (e) {
              rethrow;
            }
          }

          try {
            kdbx
              ..modifyCredentials(credentials)
              ..save();
          } catch (e) {
            kdbx.modifyCredentials(oldCredentials);
            await biometric.updateCredentials(
              context,
              oldCredentials.getHash(),
            );
            rethrow;
          }

          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          showToast(t.modify_password_throw(e.toString()));
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.modify_password),
          content: Form(
            key: formState,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  onChanged: (text) => newPassword = text,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: t.password,
                    hintText: t.input_num_password,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.length < 4
                      ? t.at_least_4digits
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: t.confirm_password,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty || value == newPassword
                            ? null
                            : t.password_not_equal,
                    onFieldSubmitted: (value) => onSetPassword(),
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: onSetPassword,
              child: Text(t.modify),
            ),
          ],
        );
      },
    );
  }
}
