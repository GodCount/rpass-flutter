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

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
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
          return AlertDialog(
            title: const Text("修改密码"),
            content: TextFormField(
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
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("取消"),
              ),
              TextButton(
                onPressed: () {},
                child: const Text("修改"),
              ),
            ],
          );
        });
  }
}
