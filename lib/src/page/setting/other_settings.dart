import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../store/index.dart';
import '../../util/fetch_favicon.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';

class _OtherSettingsArgs extends PageRouteArgs {
  _OtherSettingsArgs({super.key});
}

class OtherSettingsRoute extends PageRouteInfo<_OtherSettingsArgs> {
  OtherSettingsRoute({
    Key? key,
  }) : super(
          name,
          args: _OtherSettingsArgs(key: key),
        );

  static const name = "OtherSettingsRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_OtherSettingsArgs>(
        orElse: () => _OtherSettingsArgs(),
      );
      return OtherSettingsPage(key: args.key);
    },
  );
}

class OtherSettingsPage extends StatefulWidget {
  const OtherSettingsPage({super.key});

  @override
  State<OtherSettingsPage> createState() => _OtherSettingsPageState();
}

class _OtherSettingsPageState extends State<OtherSettingsPage>
    with SecondLevelPageAutoBack<OtherSettingsPage> {
  void _setFavIconSource() {
    final t = I18n.of(context)!;

    final favIconSource = Store.instance.settings.favIconSource;

    GestureTapCallback? autoSavePop(FavIconSource? value) {
      return () {
        Store.instance.settings.setFavIconSource(value);
        context.router.pop();
        setState(() {});
      };
    }

    showBottomSheetList(title: t.show_favicon, children: [
      ListTile(
        title: Text(t.none),
        trailing: favIconSource == null ? const Icon(Icons.check) : null,
        onTap: autoSavePop(null),
      ),
      ListTile(
        title: Text(t.direct_download),
        trailing: favIconSource == FavIconSource.Slef
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(FavIconSource.Slef),
      ),
      ListTile(
        title: const Text("Cravatar"),
        trailing: favIconSource == FavIconSource.Cravatar
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(FavIconSource.Cravatar),
      ),
      ListTile(
        title: const Text("Duckduckgo"),
        trailing: favIconSource == FavIconSource.Duckduckgo
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(FavIconSource.Duckduckgo),
      ),
      ListTile(
        title: const Text("Google"),
        trailing: favIconSource == FavIconSource.Google
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(FavIconSource.Google),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final store = Store.instance;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.more_settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(t.start_focus_sreach),
            trailing: store.settings.startFocusSreach
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              store.settings
                  .setStartFocusSreach(!store.settings.startFocusSreach);
              setState(() {});
            },
          ),
          ListTile(
            title: Text(t.show_favicon),
            subtitle: Text(t.show_favicon_sub),
            trailing: store.settings.favIconSource != null
                ? const Icon(Icons.check)
                : null,
            onTap: _setFavIconSource,
          ),
        ],
      ),
    );
  }
}
