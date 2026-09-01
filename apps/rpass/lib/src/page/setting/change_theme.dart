import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../store/index.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';

class _ChangeThemeArgs extends PageRouteArgs {
  _ChangeThemeArgs({super.key});
}

class ChangeThemeRoute extends PageRouteInfo<_ChangeThemeArgs> {
  ChangeThemeRoute({Key? key}) : super(name, args: _ChangeThemeArgs(key: key));

  static const name = "ChangeThemeRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ChangeThemeArgs>(
        orElse: () => _ChangeThemeArgs(),
      );
      return ChangeThemePage(key: args.key);
    },
  );
}

class ChangeThemePage extends StatefulWidget {
  const ChangeThemePage({super.key});

  @override
  State<ChangeThemePage> createState() => _ChangeThemePageState();
}

class _ChangeThemePageState extends State<ChangeThemePage>
    with SecondLevelPageAutoBack<ChangeThemePage> {
  void setThemeMode(ThemeMode mode) {
    Store.settings.setThemeMode(mode);
    setState(() {});
  }

  void setThemeSeedColor(Color color) {
    Store.settings.setThemeSeedColor(color);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.theme),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(t.system),
            trailing: Store.settings.themeMode == ThemeMode.system
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              setThemeMode(ThemeMode.system);
            },
          ),
          ListTile(
            title: Text(t.light),
            trailing: Store.settings.themeMode == ThemeMode.light
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              setThemeMode(ThemeMode.light);
            },
          ),
          ListTile(
            title: Text(t.dark),
            trailing: Store.settings.themeMode == ThemeMode.dark
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              setThemeMode(ThemeMode.dark);
            },
          ),

          ListTile(
            title: Text(t.seed_color),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Store.settings.themeSeedColor,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onTap: () async {
              final color = await showSelectorSeedColor(
                color: Store.settings.themeSeedColor,
              );
              if (color != null) setThemeSeedColor(color);
            },
          ),

          ListTile(
            title: Text(t.prefer_kdbx_seed_color),
            trailing: Store.settings.useKdbxSeedColor
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              Store.settings.setUseKdbxSeedColor(
                !Store.settings.useKdbxSeedColor,
              );
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
