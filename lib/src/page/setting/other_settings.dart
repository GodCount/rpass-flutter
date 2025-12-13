import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../store/index.dart';
import '../../util/cache_network_image.dart';
import '../../util/fetch_favicon.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../../widget/kdbx_icon.dart';

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
  bool _existsCache = false;

  @override
  void initState() {
    super.initState();
    KdbxIconWidget.cacheManager.size().then((value) {
      if (value > 0) {
        setState(() {
          _existsCache = true;
        });
      }
    });
  }

  void _clearCahce() async {
    try {
      final t = I18n.of(context)!;

      if (await showConfirmDialog(
        title: t.warn,
        message: t.clear_favicon_cache,
      )) {
        await KdbxIconWidget.cacheManager.clear();
        MemoryImageCacheManager.instance.clear();
        setState(() {
          _existsCache = false;
        });
      }
    } catch (e) {
      showError(e);
    }
  }

  void _setFaviconSource() {
    final t = I18n.of(context)!;

    final faviconSource = Store.instance.settings.faviconSource;

    GestureTapCallback? autoSavePop(FaviconSource? value) {
      return () {
        Store.instance.settings.setFaviconSource(value);
        context.router.pop();
        setState(() {});
      };
    }

    showBottomSheetList(title: t.show_favicon, children: [
      ListTile(
        title: Text(t.none),
        trailing: faviconSource == null ? const Icon(Icons.check) : null,
        onTap: autoSavePop(null),
      ),
      ListTile(
        title: Text(t.direct_download),
        trailing: faviconSource == FaviconSource.Slef
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(FaviconSource.Slef),
      ),
      ListTile(
        title: const Text("Cravatar"),
        trailing: faviconSource == FaviconSource.Cravatar
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(FaviconSource.Cravatar),
      ),
      ListTile(
        title: const Text("Duckduckgo"),
        trailing: faviconSource == FaviconSource.Duckduckgo
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(FaviconSource.Duckduckgo),
      ),
      ListTile(
        title: const Text("Google"),
        trailing: faviconSource == FaviconSource.Google
            ? const Icon(Icons.check)
            : null,
        onTap: autoSavePop(FaviconSource.Google),
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
            trailing: store.settings.faviconSource != null
                ? const Icon(Icons.check)
                : null,
            onTap: _setFaviconSource,
          ),
          ListTile(
            title: Text(t.clear_favicon_cache),
            enabled: _existsCache,
            onTap: _clearCahce,
          ),
        ],
      ),
    );
  }
}
