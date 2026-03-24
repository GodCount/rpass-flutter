import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../store/index.dart';
import '../../theme/theme.dart';
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
    Store.instance.settings.setThemeMode(mode);
    setState(() {});
  }

  void setThemeSeedColor(Color color) {
    Store.instance.settings.setThemeSeedColor(color);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final store = Store.instance;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.language_setting),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(t.system),
            trailing: store.settings.themeMode == ThemeMode.system
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              setThemeMode(ThemeMode.system);
            },
          ),
          ListTile(
            title: Text(t.light),
            trailing: store.settings.themeMode == ThemeMode.light
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              setThemeMode(ThemeMode.light);
            },
          ),
          ListTile(
            title: Text(t.dark),
            trailing: store.settings.themeMode == ThemeMode.dark
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              setThemeMode(ThemeMode.dark);
            },
          ),
          Padding(
            padding: const EdgeInsetsGeometry.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: availableColors.map(_buildColor).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColor(Color color) {
    return GestureDetector(
      onTap: () {
        setThemeSeedColor(color);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
        ),
        child: color == Store.instance.settings.themeSeedColor
            ? Center(child: Icon(Icons.check, color: Colors.white, size: 16))
            : null,
      ),
    );
  }
}
