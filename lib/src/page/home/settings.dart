import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../page.dart';
import '../../store/index.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});

  final Store store;

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 2,
        automaticallyImplyLeading: false,
        title: const Text("设置"),
      ),
      body: ListView(
        children: [
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.color_lens,
                    ),
                  ),
                  Text(
                    "主题",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text("系统"),
              trailing: widget.store.settings.themeMode == ThemeMode.system
                  ? const Icon(
                      Icons.check,
                    )
                  : null,
              onTap: () {
                widget.store.settings.setThemeMode(ThemeMode.system);
              },
            ),
            ListTile(
              title: const Text("亮"),
              trailing: widget.store.settings.themeMode == ThemeMode.light
                  ? const Icon(
                      Icons.check,
                    )
                  : null,
              onTap: () {
                widget.store.settings.setThemeMode(ThemeMode.light);
              },
            ),
            ListTile(
              title: const Text("暗"),
              trailing: widget.store.settings.themeMode == ThemeMode.dark
                  ? const Icon(
                      Icons.check,
                    )
                  : null,
              onTap: () {
                widget.store.settings.setThemeMode(ThemeMode.dark);
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
                    child: Icon(
                      Icons.security,
                    ),
                  ),
                  Text(
                    "安全",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text("修改密码"),
              onTap: _modifyPassword,
            ),
            ListTile(
              title: const Text("修改安全问题"),
              onTap: () {
                widget.store.settings.setThemeMode(ThemeMode.light);
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
                    child: Icon(
                      Icons.import_export,
                    ),
                  ),
                  Text(
                    "备份",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text("导入"),
              onTap: () {},
            ),
            ListTile(
              title: const Text("导出"),
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _cardColumn(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6.0)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  void _modifyPassword() {
    showDialog(
        context: context,
        builder: (context) {
          final TextEditingController controller = TextEditingController();
          final GlobalKey<FormState> formState = GlobalKey<FormState>();

          void onSetPassword() async {
            if (formState.currentState!.validate()) {
              try {
                await widget.store.verify.modifyPassword(controller.text);
                widget.store.accounts.updateToken(widget.store.verify.token!);
              } catch (e) {
                if (kDebugMode) {
                  print(e);
                }
                // TODO!
              }
            }
          }

          return AlertDialog(
            title: const Text("修改密码"),
            content: Form(
              key: formState,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: "修改 password", border: OutlineInputBorder()),
                    validator: (value) {
                      return value == null || value.trim().isEmpty
                          ? "be not empty"
                          : value.length > 3
                              ? null
                              : "must length > 3";
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: "确认 password",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        return value == controller.text ? null : "must equal";
                      },
                      onFieldSubmitted: (value) {
                        if (formState.currentState!.validate()) {
                          onSetPassword();
                        }
                      },
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
                child: const Text("取消"),
              ),
              TextButton(
                onPressed: onSetPassword,
                child: const Text("修改"),
              ),
            ],
          );
        });
  }
}
